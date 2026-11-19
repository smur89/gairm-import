// validate on each kind's shape: the type gate for leaves, recursion
// into arrays and objects with path-qualified errors, required keys
// and dependent-required. The engine walks any schema it is given, not
// just resume-schema.

#import "../lib.typ": (
  validate, schema-from-json-schema, markup, boolean, null, array-of, object,
  string, number, integer,
)

// The errors for `value` under key `k`, so every path starts at ("k",).
#let at(k, schema, value) = validate(object(((k): schema)), ((k): value))

// ---- the type gate ---------------------------------------------------

#for (schema, value) in (
  (string(), "hi"),
  (markup(), "summary text"),
  (number(), 42),
  (number(), 3.14),
  // integer(): draft 7 semantics, any number with a zero fractional
  // part, so float 2.0 passes.
  (integer(), 42),
  (integer(), 2.0),
  (boolean(), true),
  (boolean(), false),
  (null(), none),
  (array-of(string()), ("a", "b", "c")),
) {
  assert.eq(at("f", schema, value), (), message: repr((schema, value)))
}

// A wrong type is one error at the value's path.
#for (schema, value, message) in (
  (string(), 42, "expected string"),
  (number(), "nope", "expected number"),
  (integer(), 1.5, "expected an integer"),
  // A non-number fails the number gate before the integral one.
  (integer(), "nope", "expected integer, got string"),
  (boolean(), "yes", "expected boolean, got string"),
  (null(), 1, "expected null"),
  (array-of(string()), "oops", "expected array"),
  (object((a: string())), "oops", "expected object"),
) {
  let errs = at("f", schema, value)
  assert.eq(errs.len(), 1, message: repr((schema, value)))
  assert.eq(errs.at(0).path, ("f",))
  assert(errs.at(0).message.contains(message), message: errs.at(0).message)
}

// ---- arrays: each element at its indexed path ------------------------

#let errs = at("highlights", array-of(string()), ("ok", 42, "fine"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("highlights", 1))
#assert(errs.at(0).message.contains("expected string"))

// Every bad element is reported.
#assert.eq(
  at("highlights", array-of(string()), (1, "ok", 2)).map(e => e.path),
  (("highlights", 0), ("highlights", 2)),
)

// ---- objects ---------------------------------------------------------

#let person = object((name: string(), age: number()))

// Every key is optional by default.
#assert.eq(validate(person, (name: "Alice", age: 30)), ())
#assert.eq(validate(person, (name: "Alice")), ())

// An unknown key one or two edits from a valid one gets a "Did you
// mean …?" hint instead of the full Valid-keys dump.
#let errs = at("basics", person, (name: "Alice", agee: 30))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics", "agee"))
#assert(errs.at(0).message.contains("unknown key"))
#assert(errs.at(0).message.contains("\"agee\""))
#assert(errs.at(0).message.contains("Did you mean \"age\"?"))
#assert(not errs.at(0).message.contains("Valid keys"))

// With no close match (`xyz` is three edits from every key), it lists
// the valid keys.
#let errs = at("basics", person, (name: "Alice", xyz: 1))
#assert.eq(errs.len(), 1)
#assert(errs.at(0).message.contains("Valid keys: name, age."))
#assert(not errs.at(0).message.contains("Did you mean"))

// Known keys recurse; unknown-key and type errors collect together.
#assert.eq(
  at("basics", person, (name: 42, age: "old")).map(e => e.path),
  (("basics", "name"), ("basics", "age")),
)
#assert.eq(at("basics", person, (name: 42, foo: 1)).len(), 2)

// The engine walks any schema: a hand-built extension schema, not part
// of JSON Resume, validates like resume-schema does.
#let extension-schema = object((
  greeting: markup(),
  rating: number(),
  recipients: array-of(string()),
  details: object((title: string(), bullets: array-of(markup()))),
))
#assert.eq(
  validate(extension-schema, (
    greeting: "Hello",
    rating: 5,
    recipients: ("world", "everyone"),
    details: (title: "Welcome", bullets: ("first point", "second point")),
  )),
  (),
)
#assert.eq(
  validate(extension-schema, (greeting: 42, rating: "high")).map(e => (
    e.path
  )),
  (("greeting",), ("rating",)),
)

// ---- required keys ---------------------------------------------------

#let strict-person = object(
  (name: string(), email: string()),
  required-keys: ("name",),
)
#assert.eq(validate(strict-person, (name: "Alice", email: "a@x")), ())
#assert.eq(validate(strict-person, (name: "Alice")), ())
// Without required-keys, every key stays optional.
#assert.eq(validate(object((name: string())), (:)), ())

#let errs = validate(strict-person, (email: "a@x"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("name",))
#assert(errs.at(0).message.contains("missing required key"))
#assert(errs.at(0).message.contains("\"name\""))

// A type error and a missing key in one report, type error first.
#let errs = at("basics", strict-person, (email: 42))
#assert.eq(errs.map(e => e.path), (("basics", "email"), ("basics", "name")))
#assert(errs.at(0).message.contains("expected string"))
#assert(errs.at(1).message.contains("missing required key"))

// ---- dependent-required ----------------------------------------------
//
// When a key is present, its dependents must be too. Null counts as
// absent for trigger and dependent alike.

#let contact = object(
  (phone: string(), email: string(), name: string()),
  dependent-required: (phone: ("email", "name")),
)

// Trigger absent: nothing required. Trigger present: dependents too.
#assert.eq(validate(contact, (:)), ())
#assert.eq(validate(contact, (email: "a@x")), ())
#assert.eq(validate(contact, (phone: "1", email: "a@x", name: "A")), ())

// One error per missing dependent, at the missing key's path, as a
// `required` error is.
#let errs = at("basics", contact, (phone: "1", name: "A"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics", "email"))
#assert.eq(
  errs.at(0).message,
  "\"email\" is required when \"phone\" is present.",
)
#assert.eq(validate(contact, (phone: "1")).len(), 2)

// A null trigger does not fire; a null dependent is missing.
#assert.eq(validate(contact, (phone: none)), ())
#assert.eq(
  validate(contact, (phone: "1", email: none, name: "A")).len(),
  1,
)

// Absent from the node unless set.
#assert("dependent-required" not in object((a: string())))

// With `additional`, a dependent may be a key outside the shape.
#let open = object(
  (a: string()),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(validate(open, (a: "1")).len(), 1)
#assert.eq(validate(open, (a: "1", x: 2)), ())

// The translator reads dependentRequired and draft 7's array-form
// dependencies alike.
#let props = (phone: (type: "string"), email: (type: "string"))
#let from-new = schema-from-json-schema((
  type: "object",
  properties: props,
  dependentRequired: (phone: ("email",)),
))
#assert.eq(from-new.dependent-required, (phone: ("email",)))
#assert.eq(
  from-new,
  schema-from-json-schema((
    type: "object",
    properties: props,
    dependencies: (phone: ("email",)),
  )),
)

// allOf unions the dependents of one trigger.
#let abc = (a: (type: "string"), b: (type: "string"), c: (type: "string"))
#assert.eq(
  schema-from-json-schema((
    allOf: (
      (type: "object", properties: abc, dependentRequired: (a: ("b",))),
      (type: "object", properties: abc, dependentRequired: (a: ("b", "c"))),
    ),
  )).dependent-required,
  (a: ("b", "c")),
)

// A nullable object keeps the constraint on its object member.
#let nullable-contact = schema-from-json-schema((
  type: ("object", "null"),
  properties: props,
  dependentRequired: (phone: ("email",)),
))
#assert.eq(
  nullable-contact.members.at(0).dependent-required,
  (phone: ("email",)),
)
#assert.eq(
  validate(nullable-contact, (phone: "1")).map(e => e.code),
  ("dependent",),
)

// A type array's other members don't see the keywords; the object
// member keeps them.
#let mixed = schema-from-json-schema((
  type: ("object", "string"),
  properties: (a: (type: "string"), b: (type: "string")),
  dependentRequired: (a: ("b",)),
))
#assert.eq(validate(mixed, "x"), ())
#assert.eq(validate(mixed, (a: "1", b: "2")), ())
#assert(validate(mixed, (a: "1")).len() > 0)

// A key listed twice is required once: one error, not two.
#let twice = object((a: string()), required-keys: ("a", "a"))
#assert.eq(twice.required-keys, ("a",))
#assert.eq(validate(twice, (:)).len(), 1)
#assert.eq(
  object(
    (a: string(), b: string()),
    dependent-required: (a: ("b", "b")),
  ).dependent-required,
  (a: ("b",)),
)
// So in a hand-built node, which object() never saw.
#let twice-by-hand = (
  kind: "object",
  shape: (a: string(), b: string()),
  required-keys: ("a", "a"),
  dependent-required: (a: ("b", "b")),
)
#assert.eq(validate(twice-by-hand, (:)).map(e => e.code), ("required",))
#assert.eq(validate(twice-by-hand, (a: "x")).map(e => e.code), ("dependent",))
#assert.eq(
  schema-from-json-schema((
    type: "object",
    properties: (a: (type: "string")),
    required: ("a", "a"),
  )).required-keys,
  ("a",),
)

// An object that declares no keys says so, rather than listing none.
#assert.eq(
  validate(object((:)), (x: 1)).first().message,
  "unknown key \"x\". The object takes no keys.",
)

// A dependent listed twice is reported once, at the missing key.
#assert.eq(
  validate(
    object((a: string(), b: string()), dependent-required: (a: ("b", "b"))),
    (a: "1"),
  ).map(e => (e.path, e.code)),
  ((("b",), "dependent"),),
)
// A key both required and a missing dependent is reported once, as
// required.
#assert.eq(
  validate(
    object(
      (x: string(), b: string()),
      required-keys: ("b",),
      dependent-required: (x: ("b",)),
    ),
    (x: "1"),
  ).map(e => (e.path, e.code)),
  ((("b",), "required"),),
)
