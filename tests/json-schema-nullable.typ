// `type: [X, "null"]` translates to nullable(X) (#84). By default it
// validates and coerces exactly as X does: same errors, same model.
// With strict-null it accepts the null that plain X rejects. Lenses
// and paths-of-kind reach X as member 0.

#import "../lib.typ": (
  validate, coerce, parse, schema-from-json-schema, str-type, date-string,
  nullable, paths-of-kind, kind-at, lens, lens-get, lens-put, describe-schema,
)

#let T = schema-from-json-schema

// Each case: the nullable JSON Schema, the same without "null", and
// values to judge. The non-nullable translation is today's shape.
#let cases = (
  (
    (type: ("string", "null"), minLength: 2),
    (type: "string", minLength: 2),
    ("ab", "a", 1, true),
  ),
  (
    (
      type: ("object", "null"),
      properties: (a: (type: "string"), b: (type: "integer")),
      required: ("a",),
      dependentRequired: (b: ("a",)),
    ),
    (
      type: "object",
      properties: (a: (type: "string"), b: (type: "integer")),
      required: ("a",),
      dependentRequired: (b: ("a",)),
    ),
    ((a: "x"), (b: 1), (a: 1), (c: 1), (a: none, b: 2), "x"),
  ),
  (
    (type: ("array", "null"), items: (type: "string"), minItems: 2),
    (type: "array", items: (type: "string"), minItems: 2),
    (("a", "b"), ("a",), ("a", none, "b"), ("a", 1), "x"),
  ),
)

#for (nullable-js, plain-js, values) in cases {
  let n = T(nullable-js)
  let p = T(plain-js)
  assert.eq(n, nullable(p))
  for v in values {
    // Bare, inside an object, and as an array element.
    assert.eq(validate(v, schema: n), validate(v, schema: p))
    let wrap(s) = T((type: "object", properties: (f: s), required: ("f",)))
    assert.eq(
      validate((f: v), schema: wrap(nullable-js)),
      validate((f: v), schema: wrap(plain-js)),
    )
    let errs = validate(v, schema: p)
    if errs.all(e => e.code not in ("type", "enum", "union")) {
      assert.eq(coerce(v, schema: n), coerce(v, schema: p))
      assert.eq(coerce((v, none), schema: (kind: "array", elem: n)), coerce(
        (v, none),
        schema: (kind: "array", elem: p),
      ))
    }
  }
  // Null: absent by default, so required still fires and the model
  // drops it.
  let wn = T((type: "object", properties: (f: nullable-js), required: ("f",)))
  let wp = T((type: "object", properties: (f: plain-js), required: ("f",)))
  assert.eq(validate((f: none), schema: wn), validate((f: none), schema: wp))
  assert.eq(coerce((f: none), schema: wn), coerce((f: none), schema: wp))
  // Strict: the nullable field accepts it and keeps it; plain X rejects it.
  assert.eq(validate((f: none), schema: wn, strict-null: true), ())
  assert.eq(parse((f: none), schema: wn, strict-null: true), (f: none))
  assert.eq(
    validate((f: none), schema: wp, strict-null: true).map(e => e.code),
    ("type",),
  )
}

// Several types plus "null": by default the same as the types alone.
#let multi = T((type: ("string", "integer", "null")))
#let multi-plain = T((type: ("string", "integer")))
#for v in ("a", 1, 1.5, true, (a: 1)) {
  assert.eq(validate(v, schema: multi), validate(v, schema: multi-plain))
}
#assert.eq(
  validate(
    (f: none),
    schema: T((
      type: "object",
      properties: (f: (type: ("string", "integer", "null"))),
    )),
    strict-null: true,
  ),
  (),
)

// Lenses and paths-of-kind reach X at (…, 0).
#let doc = T((
  type: "object",
  properties: (
    when: (type: ("string", "null"), format: "date"),
    name: (type: ("string", "null")),
  ),
))
#assert.eq(paths-of-kind(doc, date-string), (("when", 0),))
#assert.eq(kind-at(doc, ("when",)), "union")
#assert.eq(kind-at(doc, ("when", 0)), "date-string")
#assert.eq(lens-get(lens(("name", 0)), doc), str-type)
#let renamed = lens-put(lens(("name", 0)), doc, (..str-type, min-length: 1))
#assert.eq(renamed.shape.name, nullable((..str-type, min-length: 1)))
#assert.eq(describe-schema(doc), "name  str?\nwhen  date-string?")

// allOf over a nullable object merges the objects; the merge is
// nullable only when every member is.
#let obj(p) = (type: ("object", "null"), properties: p)
#assert.eq(
  T((allOf: (obj((a: (type: "string"))), obj((b: (type: "string")))))),
  nullable(T((
    type: "object",
    properties: (a: (type: "string"), b: (type: "string")),
  ))),
)
#assert.eq(
  T((
    allOf: (
      obj((a: (type: "string"))),
      (type: "object", properties: (b: (type: "string"))),
    ),
  )),
  T((type: "object", properties: (a: (type: "string"), b: (type: "string")))),
)
