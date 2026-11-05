// `dependent-required`: when a key is present, its dependents must be
// too. Null counts as absent for trigger and dependent alike.

#import "../internal/validate.typ": _validate
#import "../internal/kinds.typ": str-type, object
#import "../lib.typ": schema-from-json-schema, remove-field, lens

#let contact = object(
  (phone: str-type, email: str-type, name: str-type),
  dependent-required: (phone: ("email", "name")),
)

// Trigger absent: nothing required.
#assert.eq(_validate(contact, (:), ()), ())
#assert.eq(_validate(contact, (email: "a@x"), ()), ())
// Trigger present, dependents present.
#assert.eq(_validate(contact, (phone: "1", email: "a@x", name: "A"), ()), ())

// One error per missing dependent, at the object's path.
#let errs = _validate(contact, (phone: "1", name: "A"), ("basics",))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics",))
#assert.eq(
  errs.at(0).message,
  "\"email\" is required when \"phone\" is present.",
)
#assert.eq(_validate(contact, (phone: "1"), ()).len(), 2)

// Null-as-absent: a null trigger does not fire; a null dependent is missing.
#assert.eq(_validate(contact, (phone: none), ()), ())
#assert.eq(
  _validate(contact, (phone: "1", email: none, name: "A"), ()).len(),
  1,
)

// Absent from the schema: default shape is unchanged.
#assert("dependent-required" not in object((a: str-type)))

// With `additional`, keys outside shape are allowed.
#let open = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(_validate(open, (a: "1"), ()).len(), 1)
#assert.eq(_validate(open, (a: "1", x: 2), ()), ())

// Translator: dependentRequired and draft 7's array-form dependencies.
#let props = (
  phone: (type: "string"),
  email: (type: "string"),
)
#let from-new = schema-from-json-schema((
  type: "object",
  properties: props,
  dependentRequired: (phone: ("email",)),
))
#let from-old = schema-from-json-schema((
  type: "object",
  properties: props,
  dependencies: (phone: ("email",)),
))
#assert.eq(from-new.dependent-required, (phone: ("email",)))
#assert.eq(from-new, from-old)

// allOf unions dependencies for the same trigger.
#let abc = (a: (type: "string"), b: (type: "string"), c: (type: "string"))
#let merged = schema-from-json-schema((
  allOf: (
    (type: "object", properties: abc, dependentRequired: (a: ("b",))),
    (type: "object", properties: abc, dependentRequired: (a: ("b", "c"))),
  ),
))
#assert.eq(merged.dependent-required, (a: ("b", "c")))

// remove-field prunes the key from every dependency, like required-keys.
#let multi = object(
  (a: str-type, b: str-type, c: str-type),
  dependent-required: (a: ("b", "c"), b: ("c",)),
)
#assert.eq(
  remove-field(multi, lens(()), "c").dependent-required,
  (a: ("b",)),
)
#assert.eq(
  remove-field(multi, lens(()), "a").dependent-required,
  (b: ("c",)),
)
#assert(
  "dependent-required"
    not in remove-field(
      object((a: str-type, b: str-type), dependent-required: (a: ("b",))),
      lens(()),
      "b",
    ),
)

// A nullable object wrap keeps the constraint.
#let nullable = schema-from-json-schema((
  type: ("object", "null"),
  properties: props,
  dependentRequired: (phone: ("email",)),
))
#assert.eq(nullable.dependent-required, (phone: ("email",)))

// A type array's non-object members don't see the dependency keywords;
// the object member keeps them.
#let mixed = schema-from-json-schema((
  type: ("object", "string"),
  properties: (a: (type: "string"), b: (type: "string")),
  dependentRequired: (a: ("b",)),
))
#assert.eq(_validate(mixed, "x", ()), ())
#assert.eq(_validate(mixed, (a: "1", b: "2"), ()), ())
#assert(_validate(mixed, (a: "1"), ()).len() > 0)
