// any-of, one-of and not-of (#108), and the unions the translator
// builds from a `type` array (#113) and from `[X, "null"]` (#84). A
// union validates against every member and models the value with the
// first that matches; `not` passes its value through as given.

#import "../lib.typ": (
  validate, coerce, parse, schema-from-json-schema, describe-schema,
  paths-of-kind, kind-at, lens, lens-get, lens-put, str-type, content-type,
  number-type, integer-type, null-type, date-string, array-of, object, enum-of,
  any-of, one-of, not-of, nullable, pattern-string,
)

#let T = schema-from-json-schema

// ---- any-of ------------------------------------------------------------

#let str-or-num = any-of((str-type, number-type))
#assert.eq(validate("hi", schema: str-or-num), ())
#assert.eq(validate(42, schema: str-or-num), ())

#let no-match = validate(true, schema: str-or-num)
#assert.eq(no-match.len(), 1)
#assert.eq(no-match.at(0).path, ())
#assert(no-match.at(0).message.contains("none matched"))
#assert(no-match.at(0).message.contains("string | number"))

// A member claims a value when it has no `type` error at the union's
// own path, read from its schema, not its error text. When one member
// claims, its own error is reported instead of the summary.
#let letter-or-num = any-of((enum-of(("a", "b")), number-type))
// The enum takes strings, not bools: no member claims `true`.
#let bool-err = validate(true, schema: letter-or-num)
#assert.eq(bool-err.map(e => e.code), ("type",))
#assert(bool-err.at(0).message.contains("none matched"))
// A string is claimed by the enum alone.
#let letter-err = validate("c", schema: letter-or-num)
#assert.eq(letter-err.map(e => e.code), ("enum",))
#assert(letter-err.at(0).message.starts-with("expected one of \"a\", \"b\""))
// A number breaking a range is claimed by the number member.
#assert(
  validate(-1, schema: any-of((
    enum-of(("a", "b")),
    (..number-type, minimum: 0),
  )))
    .at(0)
    .message
    .contains("≥ 0"),
)
// A float on an integer member is still claimed: `integer`, not `type`.
#let int-or-str = validate(1.5, schema: any-of((
  integer-type,
  pattern-string("^a"),
)))
#assert.eq(int-or-str.map(e => (e.path, e.code, e.expected, e.got)), (
  ((), "integer", none, 1.5),
))
// A type error below the union's own path doesn't stop a member claiming.
#assert.eq(
  validate((a: 1), schema: any-of((object((a: str-type)), number-type))).map(
    e => (e.path, e.code, e.expected, e.got),
  ),
  ((("a",), "type", "string", "integer"),),
)

// Inside an object, a union reports at its own path; null is absent.
#let holder = object((value: any-of((str-type, array-of(number-type)))))
#assert.eq(validate((value: (1, 2)), schema: holder), ())
#assert.eq(validate((value: "text"), schema: holder), ())
#assert.eq(validate((value: true), schema: holder).map(e => e.path), (
  ("value",),
))
#assert.eq(validate((value: none), schema: holder), ())

// Nesting stays affordable: each level validates every member once.
// Twelve levels of a member that recurses through an array, failing at
// the bottom so every branch is walked.
#let deep = str-type
#let deep-value = true
#for _ in range(12) {
  deep = any-of((deep, number-type, array-of(deep)))
  deep-value = (deep-value,)
}
#assert.eq(validate(deep-value, schema: deep).len(), 1)

// ---- one-of: exactly one -------------------------------------------------

#let exclusive = one-of((number-type, enum-of((1, 2))))
// 3 matches only number-type.
#assert.eq(validate(3, schema: exclusive), ())
// 1 matches both.
#let multi = validate(1, schema: exclusive)
#assert.eq(multi.len(), 1)
#assert(multi.at(0).message.contains("exactly one"))
#assert(multi.at(0).message.contains("2 matched"))

// ---- not-of ------------------------------------------------------------

#let not-str = not-of(str-type)
#assert.eq(validate(42, schema: not-str), ())
#assert.eq(validate((a: 1), schema: not-str), ())
#let negated = validate("nope", schema: not-str)
#assert.eq(negated.len(), 1)
#assert(negated.at(0).message.contains("not matching"))

// ---- coerce --------------------------------------------------------------

// A union models the value with the first matching member: content
// wraps, the rest pass through, inside a document too.
#let rich-or-num = any-of((content-type, number-type))
#assert.eq(type(coerce("hello", schema: rich-or-num)), content)
#assert.eq(coerce(7, schema: rich-or-num), 7)
#let doc-schema = object((x: any-of((str-type, number-type))))
#assert.eq(coerce((x: 5), schema: doc-schema).x, 5)
#assert.eq(coerce((x: "s"), schema: doc-schema).x, "s")

// `not` has no shape to coerce toward: the value passes through.
#assert.eq(coerce(42, schema: not-of(str-type)), 42)
#assert.eq(coerce((a: 1), schema: not-of(str-type)), (a: 1))

// ---- a `type` array ------------------------------------------------------
//
// One member per type, a null member last; duplicates build one member.

#let su = T((type: ("string", "number")))
#assert.eq(su, any-of((str-type, number-type)))
#assert.eq(T((type: ("string", "string"))), str-type)
#let with-null = T((type: ("string", "number", "null")))
#assert.eq(with-null, any-of((str-type, number-type, null-type)))
#assert.eq(T((type: ("null", "null"))), T((type: "null")))

#let v(s) = T((type: "object", properties: (v: s)))
#let either = v((type: ("string", "number")))
#for ok in ("a", 3, 1.5, none) {
  assert.eq(validate((v: ok), schema: either), ())
}
#assert.eq(validate((v: true), schema: either).len(), 1)
// A wrong-typed value gets the summary.
#assert(
  validate((v: true), schema: either)
    .at(0)
    .message
    .contains(
      "none matched",
    ),
)
// The null member judges no non-null value: by default the union
// reports what the types alone would.
#assert.eq(validate(true, schema: with-null), validate(true, schema: su))

// Each type's keywords apply to its own member only.
#let constrained = v((type: ("string", "integer"), minLength: 3, minimum: 10))
#for ok in ("abc", 10, 100, "a-long-string") {
  assert.eq(validate((v: ok), schema: constrained), ())
}
#assert(validate((v: 9), schema: constrained).len() > 0)
// A right-typed value that breaks a constraint reports the constraint.
#let short = validate((v: "ab"), schema: constrained)
#assert.eq(short.len(), 1)
#assert(short.at(0).message.contains("string length"))

// Containers as members.
#let mixed = v((type: ("string", "array"), items: (type: "integer")))
#assert.eq(validate((v: "x"), schema: mixed), ())
#assert.eq(validate((v: (1, 2)), schema: mixed), ())
#assert(validate((v: ("x",)), schema: mixed).len() > 0)

// Overlapping members stay valid (any-of, not one-of).
#assert.eq(validate((v: 1), schema: v((type: ("number", "integer")))), ())

// ---- nullable ------------------------------------------------------------
//
// `nullable(X)` is any-of((X, null-type)), and `type: [X, "null"]`
// translates to it. By default it validates and coerces exactly as X
// does; with strict-null it accepts the null that plain X rejects.

#assert.eq(nullable(str-type), any-of((str-type, null-type)))

// Each case: the nullable JSON Schema, the same without "null", and
// values to judge.
#for (nullable-js, plain-js, values) in (
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
) {
  let n = T(nullable-js)
  let p = T(plain-js)
  assert.eq(n, nullable(p))
  let wrap(s) = T((type: "object", properties: (f: s), required: ("f",)))
  for x in values {
    // Bare, inside an object, and as an array element.
    assert.eq(validate(x, schema: n), validate(x, schema: p))
    assert.eq(
      validate((f: x), schema: wrap(nullable-js)),
      validate((f: x), schema: wrap(plain-js)),
    )
    if validate(x, schema: p).all(e => (
      e.code not in ("type", "enum", "union")
    )) {
      assert.eq(coerce(x, schema: n), coerce(x, schema: p))
      assert.eq(
        coerce((x, none), schema: (kind: "array", elem: n)),
        coerce((x, none), schema: (kind: "array", elem: p)),
      )
    }
  }
  // Null: absent by default, so required still fires and the model
  // drops it.
  let (wn, wp) = (wrap(nullable-js), wrap(plain-js))
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
#for x in ("a", 1, 1.5, true, (a: 1)) {
  assert.eq(
    validate(x, schema: multi),
    validate(x, schema: T((type: ("string", "integer")))),
  )
}
#assert.eq(
  validate(
    (v: none),
    schema: v((type: ("string", "integer", "null"))),
    strict-null: true,
  ),
  (),
)

// Lenses, kind-at and paths-of-kind reach X as member 0.
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
#assert.eq(lens-get(doc, ("name", 0)), str-type)
#assert.eq(
  lens-put(doc, ("name", 0), (..str-type, min-length: 1)).shape.name,
  nullable((..str-type, min-length: 1)),
)
#assert.eq(describe-schema(doc), "name  string?\nwhen  date-string?")

// allOf over nullable objects merges the objects; the merge is nullable
// only when every member is.
#let obj(p) = (type: ("object", "null"), properties: p)
#let ab = T((
  type: "object",
  properties: (a: (type: "string"), b: (type: "string")),
))
#assert.eq(
  T((allOf: (obj((a: (type: "string"))), obj((b: (type: "string")))))),
  nullable(ab),
)
#assert.eq(
  T((
    allOf: (
      obj((a: (type: "string"))),
      (type: "object", properties: (b: (type: "string"))),
    ),
  )),
  ab,
)
