// validate on each kind's shape: the type gate for leaves, recursion
// into arrays and objects with path-qualified errors, required keys
// and dependent-required. The engine walks any schema it is given, not
// just resume-schema.

#import "../lib.typ": (
  validate, schema-from-json-schema, str-type, content-type, number-type,
  integer-type, bool-type, null-type, array-of, object,
)

// The errors for `value` under key `k`, so every path starts at ("k",).
#let at(k, schema, value) = validate(
  ((k): value),
  schema: object(((k): schema)),
)

// ---- the type gate ---------------------------------------------------

#for (schema, value) in (
  (str-type, "hi"),
  (content-type, "summary text"),
  (number-type, 42),
  (number-type, 3.14),
  // integer-type: draft 7 semantics, any number with a zero fractional
  // part, so float 2.0 passes.
  (integer-type, 42),
  (integer-type, 2.0),
  (bool-type, true),
  (bool-type, false),
  (null-type, none),
  (array-of(str-type), ("a", "b", "c")),
) {
  assert.eq(at("f", schema, value), (), message: repr((schema, value)))
}

// A wrong type is one error at the value's path.
#for (schema, value, message) in (
  (str-type, 42, "expected string"),
  (number-type, "nope", "expected number"),
  (integer-type, 1.5, "expected an integer"),
  // A non-number fails the number gate before the integral one.
  (integer-type, "nope", "expected number"),
  (bool-type, "yes", "expected boolean, got string"),
  (null-type, 1, "expected null"),
  (array-of(str-type), "oops", "expected array"),
  (object((a: str-type)), "oops", "expected object"),
) {
  let errs = at("f", schema, value)
  assert.eq(errs.len(), 1, message: repr((schema, value)))
  assert.eq(errs.at(0).path, ("f",))
  assert(errs.at(0).message.contains(message), message: errs.at(0).message)
}

// ---- arrays: each element at its indexed path ------------------------

#let errs = at("highlights", array-of(str-type), ("ok", 42, "fine"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("highlights", 1))
#assert(errs.at(0).message.contains("expected string"))

// Every bad element is reported.
#assert.eq(
  at("highlights", array-of(str-type), (1, "ok", 2)).map(e => e.path),
  (("highlights", 0), ("highlights", 2)),
)

// ---- objects ---------------------------------------------------------

#let person = object((name: str-type, age: number-type))

// Every key is optional by default.
#assert.eq(validate((name: "Alice", age: 30), schema: person), ())
#assert.eq(validate((name: "Alice"), schema: person), ())

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
  greeting: content-type,
  rating: number-type,
  recipients: array-of(str-type),
  details: object((title: str-type, bullets: array-of(content-type))),
))
#assert.eq(
  validate(
    (
      greeting: "Hello",
      rating: 5,
      recipients: ("world", "everyone"),
      details: (title: "Welcome", bullets: ("first point", "second point")),
    ),
    schema: extension-schema,
  ),
  (),
)
#assert.eq(
  validate((greeting: 42, rating: "high"), schema: extension-schema).map(e => (
    e.path
  )),
  (("greeting",), ("rating",)),
)

// ---- required keys ---------------------------------------------------

#let strict-person = object(
  (name: str-type, email: str-type),
  required-keys: ("name",),
)
#assert.eq(validate((name: "Alice", email: "a@x"), schema: strict-person), ())
#assert.eq(validate((name: "Alice"), schema: strict-person), ())
// Without required-keys, every key stays optional.
#assert.eq(validate((:), schema: object((name: str-type))), ())

#let errs = validate((email: "a@x"), schema: strict-person)
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
  (phone: str-type, email: str-type, name: str-type),
  dependent-required: (phone: ("email", "name")),
)

// Trigger absent: nothing required. Trigger present: dependents too.
#assert.eq(validate((:), schema: contact), ())
#assert.eq(validate((email: "a@x"), schema: contact), ())
#assert.eq(validate((phone: "1", email: "a@x", name: "A"), schema: contact), ())

// One error per missing dependent, at the object's path.
#let errs = at("basics", contact, (phone: "1", name: "A"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics",))
#assert.eq(
  errs.at(0).message,
  "\"email\" is required when \"phone\" is present.",
)
#assert.eq(validate((phone: "1"), schema: contact).len(), 2)

// A null trigger does not fire; a null dependent is missing.
#assert.eq(validate((phone: none), schema: contact), ())
#assert.eq(
  validate((phone: "1", email: none, name: "A"), schema: contact).len(),
  1,
)

// Absent from the node unless set.
#assert("dependent-required" not in object((a: str-type)))

// With `additional`, a dependent may be a key outside the shape.
#let open = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(validate((a: "1"), schema: open).len(), 1)
#assert.eq(validate((a: "1", x: 2), schema: open), ())

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
  validate((phone: "1"), schema: nullable-contact).map(e => e.code),
  ("dependent",),
)

// A type array's other members don't see the keywords; the object
// member keeps them.
#let mixed = schema-from-json-schema((
  type: ("object", "string"),
  properties: (a: (type: "string"), b: (type: "string")),
  dependentRequired: (a: ("b",)),
))
#assert.eq(validate("x", schema: mixed), ())
#assert.eq(validate((a: "1", b: "2"), schema: mixed), ())
#assert(validate((a: "1"), schema: mixed).len() > 0)
