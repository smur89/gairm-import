// The constraint keywords (#76): string length, number range and
// multiple, array items and uniqueness. The translator writes each as a
// kebab-case field on the node; validate checks it after the type.

#import "../lib.typ": (
  validate, schema-from-json-schema, str-type, array-of, object,
)

#let T = schema-from-json-schema

// ---- what each node takes and rejects --------------------------------------
//
// Each row: a node, the values it takes, and values it rejects with one
// error whose message contains the given text.

#for (node, good, bad) in (
  (
    (kind: "str", min-length: 3, max-length: 5),
    ("abc", "abcde"),
    (("ab", "≥ 3, got 2"), ("abcdef", "≤ 5, got 6")),
  ),
  // Length counts grapheme clusters, not bytes.
  ((kind: "str", min-length: 1), ("🙂",), ()),
  (
    (kind: "number", minimum: 1, maximum: 10),
    (1, 10, 5.5),
    ((0, "≥ 1"), (11, "≤ 10")),
  ),
  // Exclusive bounds reject the boundary itself.
  (
    (kind: "number", exclusive-minimum: 1, exclusive-maximum: 10),
    (2, 9),
    ((1, "> 1"), (10, "< 10")),
  ),
  (
    (kind: "number", multiple-of: 3),
    (0, 9),
    ((10, "multiple of 3"), (1.5, "")),
  ),
  // Float multiples tolerate rounding: calc.rem(0.3, 0.1) is not 0.
  ((kind: "number", multiple-of: 0.1), (0.3, 3), ((0.35, ""),)),
  (
    (kind: "array", elem: str-type, min-items: 2, max-items: 3),
    (("a", "b"), ("a", "b", "c")),
    ((("a",), "≥ 2"), (("a", "b", "c", "d"), "≤ 3")),
  ),
  // uniqueItems reports the first duplicate, by index.
  (
    (kind: "array", elem: str-type, unique-items: true),
    (("a", "b", "c"),),
    ((("a", "b", "a"), "duplicate at indices 0 and 2"),),
  ),
  // Deep equality: dicts with the same content are duplicates.
  (
    (kind: "array", elem: object((k: str-type)), unique-items: true),
    (),
    ((((k: "x"), (k: "x")), ""),),
  ),
) {
  for v in good { assert.eq(validate(v, schema: node), (), message: repr(v)) }
  for (v, text) in bad {
    let errs = validate(v, schema: node)
    assert.eq(errs.len(), 1, message: repr(v))
    assert(errs.at(0).message.contains(text), message: errs.at(0).message)
  }
}

// A quotient too large for a float (the JSON Schema test suite's "float
// division = inf") is not a multiple, rather than a crash comparing NaN.
#let mult-tiny = T((type: "number", multipleOf: 0.123456789))
#assert.eq(validate(1e308, schema: mult-tiny).map(e => e.code), ("multiple",))
#assert.eq(validate(0.246913578, schema: mult-tiny), ())

// ---- translation -----------------------------------------------------------

#for (js, node) in (
  (
    (type: "string", minLength: 1, maxLength: 64),
    (
      kind: "str",
      min-length: 1,
      max-length: 64,
    ),
  ),
  (
    (type: "number", minimum: 0, exclusiveMaximum: 100, multipleOf: 0.5),
    (kind: "number", minimum: 0, exclusive-maximum: 100, multiple-of: 0.5),
  ),
  (
    (type: "array", items: (type: "string"), minItems: 1, uniqueItems: true),
    (kind: "array", elem: str-type, min-items: 1, unique-items: true),
  ),
  // `uniqueItems: false` is the default, so it is left out.
  (
    (type: "array", items: (type: "string"), uniqueItems: false),
    array-of(
      str-type,
    ),
  ),
  // A count takes a whole-number float, as `integer` does (draft 7;
  // the JSON Schema test suite's "float value with zero fractional
  // part"), stored as an int so the bound reads as one.
  (
    (type: "string", minLength: 2.0, maxLength: 4.0),
    (
      kind: "str",
      min-length: 2,
      max-length: 4,
    ),
  ),
  (
    (type: "array", items: (type: "string"), minItems: 1.0, maxItems: 3.0),
    (kind: "array", elem: str-type, min-items: 1, max-items: 3),
  ),
  // Constraints carry through a format kind.
  (
    (type: "string", format: "email", maxLength: 254),
    (
      kind: "email-string",
      max-length: 254,
    ),
  ),
) {
  assert.eq(T(js), node)
}
#assert.eq(
  validate("a", schema: T((type: "string", minLength: 2.0))).at(0).message,
  "expected string length ≥ 2, got 1.",
)

// End to end: each keyword through the translator, then validate. A
// field-name typo on either side would let the value pass.
#for (js, value, text) in (
  ((type: "string", minLength: 3), "ab", "≥ 3"),
  ((type: "string", maxLength: 3), "abcd", "≤ 3"),
  ((type: "number", minimum: 1), 0, "≥ 1"),
  ((type: "number", maximum: 10), 11, "≤ 10"),
  ((type: "number", exclusiveMinimum: 1), 1, "> 1"),
  ((type: "number", exclusiveMaximum: 10), 10, "< 10"),
  ((type: "number", multipleOf: 3), 10, "multiple of 3"),
  ((type: "array", items: (type: "string"), minItems: 2), ("a",), "≥ 2"),
  ((type: "array", items: (type: "string"), maxItems: 1), ("a", "b"), "≤ 1"),
  (
    (type: "array", items: (type: "string"), uniqueItems: true),
    ("a", "a"),
    "duplicate",
  ),
) {
  let errs = validate(value, schema: T(js))
  assert(errs.len() > 0, message: "expected an error for " + repr(js))
  assert(errs.at(0).message.contains(text), message: errs.at(0).message)
}

// ---- in a document -------------------------------------------------------

// Constraint errors carry the full path, beside other fields' errors.
#let bad-person = validate((name: "", age: -1), schema: object(
  (
    name: (kind: "str", min-length: 1),
    age: (kind: "number", minimum: 0),
  ),
  required-keys: ("name",),
))
#assert.eq(bad-person.map(e => e.path), (("name",), ("age",)))
#assert(bad-person.at(0).message.contains("≥ 1"))
#assert(bad-person.at(1).message.contains("≥ 0"))

// Null elements are dropped from the model, so min-items and
// unique-items count what is left; the duplicate report cites the
// original indices.
#let min-two = (kind: "array", elem: str-type, min-items: 2)
#assert.eq(validate(("a", none, "b"), schema: min-two), ())
#assert(validate(("a", none), schema: min-two).at(0).message.contains("got 1"))
#let unique = (kind: "array", elem: str-type, unique-items: true)
#assert.eq(validate(("a", none, "b", none), schema: unique), ())
#let dup = validate(("a", none, "b", "a"), schema: unique)
#assert.eq(dup.len(), 1)
#assert(dup.at(0).message.contains("indices 0 and 3"))
