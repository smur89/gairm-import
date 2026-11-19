// The constraint keywords (#76): string length, number range and
// multiple, array items and uniqueness. The translator writes each as a
// kebab-case field on the node; validate checks it after the type.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, array-of, object, string, number,
  integer, any-type,
)

#let T = schema-from-json-schema

// ---- what each node takes and rejects --------------------------------------
//
// Each row: a node, the values it takes, and values it rejects with one
// error whose message contains the given text.

#for (node, good, bad) in (
  (
    (kind: "string", min-length: 3, max-length: 5),
    ("abc", "abcde"),
    (("ab", "≥ 3, got 2"), ("abcdef", "≤ 5, got 6")),
  ),
  // Length counts grapheme clusters, not bytes.
  ((kind: "string", min-length: 1), ("🙂",), ()),
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
    (kind: "array", elem: string(), min-items: 2, max-items: 3),
    (("a", "b"), ("a", "b", "c")),
    ((("a",), "≥ 2"), (("a", "b", "c", "d"), "≤ 3")),
  ),
  // uniqueItems reports the first duplicate, by index.
  (
    (kind: "array", elem: string(), unique-items: true),
    (("a", "b", "c"),),
    ((("a", "b", "a"), "duplicate at indices 0 and 2"),),
  ),
  // Deep equality: dicts with the same content are duplicates.
  (
    (kind: "array", elem: object((k: string())), unique-items: true),
    (),
    ((((k: "x"), (k: "x")), ""),),
  ),
) {
  for v in good { assert.eq(validate(node, v), (), message: repr(v)) }
  for (v, text) in bad {
    let errs = validate(node, v)
    assert.eq(errs.len(), 1, message: repr(v))
    assert(errs.at(0).message.contains(text), message: errs.at(0).message)
  }
}

// A quotient too large for a float (the JSON Schema test suite's "float
// division = inf") is not a multiple, rather than a crash comparing NaN.
#let mult-tiny = T((type: "number", multipleOf: 0.123456789))
#assert.eq(validate(mult-tiny, 1e308).map(e => e.code), ("multiple",))
#assert.eq(validate(mult-tiny, 0.246913578), ())

// ---- translation -----------------------------------------------------------

#for (js, node) in (
  (
    (type: "string", minLength: 1, maxLength: 64),
    (
      kind: "string",
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
    (kind: "array", elem: string(), min-items: 1, unique-items: true),
  ),
  // `uniqueItems: false` is the default, so it is left out.
  (
    (type: "array", items: (type: "string"), uniqueItems: false),
    array-of(
      string(),
    ),
  ),
  // A count takes a whole-number float, as `integer` does (draft 7;
  // the JSON Schema test suite's "float value with zero fractional
  // part"), stored as an int so the bound reads as one.
  (
    (type: "string", minLength: 2.0, maxLength: 4.0),
    (
      kind: "string",
      min-length: 2,
      max-length: 4,
    ),
  ),
  (
    (type: "array", items: (type: "string"), minItems: 1.0, maxItems: 3.0),
    (kind: "array", elem: string(), min-items: 1, max-items: 3),
  ),
  // Constraints carry through a format.
  (
    (type: "string", format: "email", maxLength: 254),
    (
      kind: "string",
      format: "email",
      max-length: 254,
    ),
  ),
) {
  assert.eq(T(js), node)
}
#assert.eq(
  validate(T((type: "string", minLength: 2.0)), "a").at(0).message,
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
  let errs = validate(T(js), value)
  assert(errs.len() > 0, message: "expected an error for " + repr(js))
  assert(errs.at(0).message.contains(text), message: errs.at(0).message)
}

// ---- in a document -------------------------------------------------------

// Constraint errors carry the full path, beside other fields' errors.
#let bad-person = validate(
  object(
    (
      name: (kind: "string", min-length: 1),
      age: (kind: "number", minimum: 0),
    ),
    required-keys: ("name",),
  ),
  (name: "", age: -1),
)
#assert.eq(bad-person.map(e => e.path), (("name",), ("age",)))
#assert(bad-person.at(0).message.contains("≥ 1"))
#assert(bad-person.at(1).message.contains("≥ 0"))

// Null elements are dropped from the model, so min-items and
// unique-items count what is left; the duplicate report cites the
// original indices.
#let min-two = (kind: "array", elem: string(), min-items: 2)
#assert.eq(validate(min-two, ("a", none, "b")), ())
#assert(validate(min-two, ("a", none)).at(0).message.contains("got 1"))
#let unique = (kind: "array", elem: string(), unique-items: true)
#assert.eq(validate(unique, ("a", none, "b", none)), ())
#let dup = validate(unique, ("a", none, "b", "a"))
#assert.eq(dup.len(), 1)
#assert(dup.at(0).message.contains("indices 0 and 3"))

// Uniqueness: the all-unique fast path and the pairwise search agree,
// `1` and `1.0` included, and a duplicate is still cited by its first
// pair of source indices.
#let uniq = array-of(number(), unique-items: true)
#assert.eq(validate(uniq, range(500)), ())
#assert.eq(
  validate(uniq, range(500) + (3,)).map(e => e.got),
  ((3, 500),),
)
#assert.eq(validate(uniq, (1, 1.0)).map(e => e.got), ((0, 1),))

// Dictionaries equal in content are duplicates whatever their key order.
#let pairs = array-of(object((a: number(), b: number())), unique-items: true)
#assert.eq(
  validate(pairs, ((a: 1, b: 2), (b: 2, a: 1))).map(e => e.code),
  ("unique",),
)
// With several duplicate pairs, the one cited is the first item's.
#assert.eq(validate(uniq, (1, 2, 2, 1)).map(e => e.got), ((0, 3),))

// Strings take the one-pass path; it cites the same pair as the
// equality scan, and mixed arrays still go through that scan.
#let uniq-str = array-of(string(), unique-items: true)
#assert.eq(validate(uniq-str, ("a", "b", "b", "a")).map(e => e.got), ((0, 3),))
#assert.eq(validate(uniq-str, range(500).map(str)), ())
#assert.eq(
  validate(array-of(any-type, unique-items: true), ("1", 1, 1.0)).map(e => (
    e.got
  )),
  ((1, 2),),
)

// ---- decimal ---------------------------------------------------------------
//
// A Typst `decimal` is a number: JSON never gives one, but data written
// in Typst may. It is judged against int and float bounds alike, and
// modelled as given.
#let d = decimal("1.5")
#assert.eq(validate(number(minimum: 1, maximum: 1.6), d), ())
#assert.eq(coerce(number(), d), d)
#assert.eq(validate(number(minimum: 1.6), d).map(e => e.code), ("range",))
#assert.eq(validate(number(exclusive-maximum: 1), d).map(e => e.code), (
  "range",
))
#assert.eq(validate(number(multiple-of: 0.5), d), ())
#assert.eq(validate(number(multiple-of: 1), d).map(e => e.code), ("multiple",))
// A float bound compares as the decimal it is written as, so the
// value's precision survives: past `maximum: 1.0` by 1e-20 is out, and
// past `exclusive-minimum: 1.0` by as much is in. A bound no decimal can
// hold still compares.
#let past-one = decimal("1.00000000000000000001")
#assert.eq(validate(number(maximum: 1.0), past-one).map(e => e.code), (
  "range",
))
#assert.eq(validate(number(exclusive-minimum: 1.0), past-one), ())
#assert.eq(validate(number(maximum: 1.6), decimal("1.6")), ())
#assert.eq(validate(number(maximum: float.inf), d), ())
#assert.eq(validate(number(minimum: 1e300), d).map(e => e.code), ("range",))
// So does a float multiple: exact, where floats need a tolerance.
#assert.eq(validate(number(multiple-of: 0.1), decimal("0.3")), ())
#assert.eq(
  validate(number(multiple-of: 0.1), decimal("0.30000000001")).map(e => e.code),
  ("multiple",),
)
#assert.eq(validate(integer(), decimal("2.0")), ())
#assert.eq(validate(integer(), d).map(e => e.code), ("integer",))
#assert.eq(
  validate(string(), d).first().message,
  "expected string, got number.",
)
