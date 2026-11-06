// Draft 7 nodes with no `type`: `{}` takes any value, and a
// type-specific keyword constrains only values of its own type. Cases
// adapted from the JSON Schema test suite.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, describe-schema, any-type,
  str-type, number-type, bool-type, null-type, array-of, object, any-of,
)

// One value of every JSON type, and some nesting.
#let every-type = (
  none,
  true,
  false,
  0,
  -1.5,
  "",
  "a",
  (),
  (1, "a", none),
  (:),
  (a: (b: none)),
)

// Under a field, so null can be tried: a document's root must be a
// value. An optional field, so a default-mode null is simply absent.
#let check(js, value, strict, valid) = {
  let errs = validate(
    (x: value),
    schema: object((x: schema-from-json-schema(js))),
    strict-null: strict,
  )
  assert.eq(
    errs.len() == 0,
    valid,
    message: repr(js)
      + " on "
      + repr(value)
      + " (strict-null: "
      + repr(strict)
      + "): "
      + repr(errs),
  )
}
#let ok(js, value, strict) = check(js, value, strict, true)
#let fails(js, value, strict) = check(js, value, strict, false)

// ---- translation ----------------------------------------------------

#assert.eq(schema-from-json-schema((:)), any-type)
// Annotations alone constrain nothing.
#assert.eq(
  schema-from-json-schema((title: "x", description: "anything")),
  any-type,
)
#assert.eq(schema-from-json-schema((type: "array")), array-of(any-type))
#assert.eq(
  schema-from-json-schema((type: "array", minItems: 1)),
  (..array-of(any-type), min-items: 1),
)
#assert.eq(
  schema-from-json-schema((
    type: "object",
    properties: (anything: (:)),
  ))
    .shape
    .anything,
  any-type,
)

// One member per JSON type; the keyword narrows only its own type's
// member, the rest take any value of their type.
#assert.eq(
  schema-from-json-schema((minLength: 2)),
  any-of((
    bool-type,
    object((:), additional: true),
    array-of(any-type),
    number-type,
    (..str-type, min-length: 2),
    null-type,
  )),
)

#assert.eq(describe-schema(any-type), "any")

// ---- {} accepts every value, unchanged ------------------------------

#for strict in (false, true) {
  for v in every-type { ok((:), v, strict) }
  for v in every-type {
    ok((type: "object", properties: (x: (:))), (x: v), strict)
  }
}
#assert.eq(coerce((a: (1, none), b: "x"), schema: any-type), (
  a: (1, none),
  b: "x",
))
#assert.eq(
  coerce((x: none), schema: object((x: any-type)), strict-null: true),
  (x: none),
)

// ---- a keyword constrains its own type only -------------------------

#for strict in (false, true) {
  // minLength
  fails((minLength: 2), "a", strict)
  for v in ("ab", 1, none, (), (:), true) { ok((minLength: 2), v, strict) }

  // format
  fails((format: "date"), "x", strict)
  for v in ("2024-01-15", 1, none, ("x",)) { ok((format: "date"), v, strict) }

  // minimum
  fails((minimum: 1), 0, strict)
  for v in (1, "a", none, (0,)) { ok((minimum: 1), v, strict) }

  // items without type: arrays only
  fails((items: (type: "string")), (1,), strict)
  for v in (("a",), 1, "a") { ok((items: (type: "string")), v, strict) }

  // properties without type: objects only (closed, like a typed object
  // with properties and no additionalProperties)
  let props = (properties: (a: (type: "string")))
  fails(props, (a: 1), strict)
  fails(props, (b: "x"), strict)
  for v in ((a: "x"), (:), "x", 1, none, (1,)) { ok(props, v, strict) }

  // required without properties: an object with the key, any extras
  fails((required: ("a",)), (b: 1), strict)
  for v in ((a: 1, b: 2), "x", 1) { ok((required: ("a",)), v, strict) }

  // dependencies without type: objects only
  let deps = (dependencies: (a: ("b",)))
  fails(deps, (a: 1), strict)
  for v in ((a: 1, b: 2), (c: 1), "x") { ok(deps, v, strict) }

  // type: array without items
  ok((type: "array"), (1, "a", none), strict)
  ok((type: "array"), (), strict)
  fails((type: "array"), "a", strict)
}

// ---- errors stay the narrowed member's own --------------------------

#let short = validate("a", schema: schema-from-json-schema((minLength: 2)))
#assert.eq(short.len(), 1)
#assert.eq(short.at(0).code, "length")
#assert.eq(short.at(0).path, ())
#assert.eq(short.at(0).message, "expected string length ≥ 2, got 1.")

#let low = validate(0, schema: schema-from-json-schema((minimum: 1)))
#assert.eq(low.len(), 1)
#assert.eq(low.at(0).message, "expected ≥ 1, got 0.")

#let bad-date = validate("x", schema: schema-from-json-schema((
  format: "date",
)))
#assert.eq(bad-date.len(), 1)
#assert.eq(bad-date.at(0).code, "format")
