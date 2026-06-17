// JSON Schema constraint keywords — #76. Translator harvests the
// per-type constraints into kebab-case fields on the kind dict;
// validator branches read those fields after the type check.

#import "../lib.typ": (
  validate,
  schema-from-json-schema,
  str-type, number-type, array-of, object,
)

// --- string length ---------------------------------------------------

#let len-3-5 = (kind: "str", min-length: 3, max-length: 5)

#assert.eq(validate("abc", schema: len-3-5), ())
#assert.eq(validate("abcde", schema: len-3-5), ())

#let short = validate("ab", schema: len-3-5)
#assert.eq(short.len(), 1)
#assert(short.at(0).message.contains("≥ 3"))
#assert(short.at(0).message.contains("got 2"))

#let long = validate("abcdef", schema: len-3-5)
#assert.eq(long.len(), 1)
#assert(long.at(0).message.contains("≤ 5"))
#assert(long.at(0).message.contains("got 6"))

// Multi-cluster strings (emoji + combining marks) count per cluster,
// not per byte: "🙂" is one cluster — passes a min-length: 1 gate.
#let one-cluster = (kind: "str", min-length: 1)
#assert.eq(validate("🙂", schema: one-cluster), ())

// --- number range ----------------------------------------------------

#let inc-1-10 = (kind: "number", minimum: 1, maximum: 10)
#assert.eq(validate(1, schema: inc-1-10), ())
#assert.eq(validate(10, schema: inc-1-10), ())
#assert.eq(validate(5.5, schema: inc-1-10), ())

#let below = validate(0, schema: inc-1-10)
#assert.eq(below.len(), 1)
#assert(below.at(0).message.contains("≥ 1"))

#let above = validate(11, schema: inc-1-10)
#assert.eq(above.len(), 1)
#assert(above.at(0).message.contains("≤ 10"))

// Exclusive bounds reject the boundary itself.
#let exc-1-10 = (kind: "number", exclusive-minimum: 1, exclusive-maximum: 10)
#assert.eq(validate(2, schema: exc-1-10), ())
#assert.eq(validate(9, schema: exc-1-10), ())

#let at-emin = validate(1, schema: exc-1-10)
#assert.eq(at-emin.len(), 1)
#assert(at-emin.at(0).message.contains("> 1"))

#let at-emax = validate(10, schema: exc-1-10)
#assert.eq(at-emax.len(), 1)
#assert(at-emax.at(0).message.contains("< 10"))

// multipleOf
#let mult-3 = (kind: "number", multiple-of: 3)
#assert.eq(validate(0, schema: mult-3), ())
#assert.eq(validate(9, schema: mult-3), ())
#let off-mult = validate(10, schema: mult-3)
#assert.eq(off-mult.len(), 1)
#assert(off-mult.at(0).message.contains("multiple of 3"))

// --- array constraints -----------------------------------------------

#let arr-2-3 = (kind: "array", elem: str-type, min-items: 2, max-items: 3)
#assert.eq(validate(("a", "b"), schema: arr-2-3), ())
#assert.eq(validate(("a", "b", "c"), schema: arr-2-3), ())

#let too-few = validate(("a",), schema: arr-2-3)
#assert.eq(too-few.len(), 1)
#assert(too-few.at(0).message.contains("≥ 2"))

#let too-many = validate(("a", "b", "c", "d"), schema: arr-2-3)
#assert.eq(too-many.len(), 1)
#assert(too-many.at(0).message.contains("≤ 3"))

// uniqueItems flags the first duplicate it finds.
#let unique-arr = (kind: "array", elem: str-type, unique-items: true)
#assert.eq(validate(("a", "b", "c"), schema: unique-arr), ())
#let dup = validate(("a", "b", "a"), schema: unique-arr)
#assert.eq(dup.len(), 1)
#assert(dup.at(0).message.contains("duplicate"))
#assert(dup.at(0).message.contains("indices 0 and 2"))

// Deep equality: dict elements with the same content compare equal.
#let unique-dicts = (kind: "array", elem: object((k: str-type)), unique-items: true)
#let same-shape = (
  (k: "x"),
  (k: "x"),
)
#let dup-dict = validate(same-shape, schema: unique-dicts)
#assert.eq(dup-dict.len(), 1)

// --- translator: round-trips through schema-from-json-schema --------

#assert.eq(
  schema-from-json-schema((type: "string", minLength: 1, maxLength: 64)),
  (kind: "str", min-length: 1, max-length: 64),
)
#assert.eq(
  schema-from-json-schema((
    type: "number",
    minimum: 0,
    exclusiveMaximum: 100,
    multipleOf: 0.5,
  )),
  (kind: "number", minimum: 0, exclusive-maximum: 100, multiple-of: 0.5),
)
#assert.eq(
  schema-from-json-schema((
    type: "array",
    items: (type: "string"),
    minItems: 1,
    uniqueItems: true,
  )),
  (kind: "array", elem: str-type, min-items: 1, unique-items: true),
)
// `uniqueItems: false` is the default — omit from the dict to keep the
// no-constraint case as a plain dict.
#assert.eq(
  schema-from-json-schema((type: "array", items: (type: "string"), uniqueItems: false)),
  array-of(str-type),
)

// Constraints carry through format-specialised strings.
#assert.eq(
  schema-from-json-schema((type: "string", format: "email", maxLength: 254)),
  (kind: "email-string", max-length: 254),
)

// --- translator: source-shape errors panic at translate time --------
//
// Source-level pin on each bail message — Typst can't catch panics so
// we assert the diagnostic exists rather than triggering it.
#let src = read("../internal/json-schema.typ")
#assert(src.contains("must be a non-negative integer"))
#assert(src.contains("must be a number"))
#assert(src.contains("must be > 0"))
#assert(src.contains("must be a boolean"))
#assert(src.contains("is unsatisfiable"))
#assert(src.contains("leave no satisfying value"))

// --- end-to-end roundtrip: translator → validator catches field typos
//
// Each constraint goes source → schema-from-json-schema → validate.
// If either side has a typo in the kebab-case field name (translator
// emits "min-length", validator reads "min-length"), the validator
// would silently return () instead of firing. Each assertion below
// pins both halves.

#let _expect-error(src-schema, input) = {
  let errs = validate(input, schema: schema-from-json-schema(src-schema))
  assert(errs.len() > 0, message: "expected ≥1 error for " + repr(input))
  errs.at(0)
}

#assert(_expect-error((type: "string", minLength: 3), "ab").message.contains("≥ 3"))
#assert(_expect-error((type: "string", maxLength: 3), "abcd").message.contains("≤ 3"))
#assert(_expect-error((type: "number", minimum: 1), 0).message.contains("≥ 1"))
#assert(_expect-error((type: "number", maximum: 10), 11).message.contains("≤ 10"))
#assert(_expect-error((type: "number", exclusiveMinimum: 1), 1).message.contains("> 1"))
#assert(_expect-error((type: "number", exclusiveMaximum: 10), 10).message.contains("< 10"))
#assert(_expect-error((type: "number", multipleOf: 3), 10).message.contains("multiple of 3"))
#assert(_expect-error(
  (type: "array", items: (type: "string"), minItems: 2),
  ("a",),
).message.contains("≥ 2"))
#assert(_expect-error(
  (type: "array", items: (type: "string"), maxItems: 1),
  ("a", "b"),
).message.contains("≤ 1"))
#assert(_expect-error(
  (type: "array", items: (type: "string"), uniqueItems: true),
  ("a", "a"),
).message.contains("duplicate"))

// --- null-as-absent applies to array constraints --------------------
//
// `coerce` drops null elements, so the rendered model loses them.
// Length / uniqueness constraints have to count the rendered shape,
// not the raw input, or a min-items: 3 array of (a, null, b) would
// validate as 3-long but render as 2-long — silently inconsistent.

#let nones-skipped = (kind: "array", elem: str-type, min-items: 2)
#assert.eq(validate(("a", none, "b"), schema: nones-skipped), ())
#let too-few-after-nones = validate(("a", none), schema: nones-skipped)
#assert.eq(too-few-after-nones.len(), 1)
#assert(too-few-after-nones.at(0).message.contains("got 1"))

// uniqueItems likewise compares non-null entries only — but the
// duplicate-index report cites the *original* positions so the
// caller can find them in the source array.
#let unique-with-nones = (kind: "array", elem: str-type, unique-items: true)
#assert.eq(validate(("a", none, "b", none), schema: unique-with-nones), ())
#let dup-with-none = validate(("a", none, "b", "a"), schema: unique-with-nones)
#assert.eq(dup-with-none.len(), 1)
#assert(dup-with-none.at(0).message.contains("indices 0 and 3"))

// --- integration with required + nested path -------------------------
//
// Constraint errors surface with the full nested path, alongside any
// type errors from sibling fields.
#let person = object(
  (
    name: (kind: "str", min-length: 1),
    age: (kind: "number", minimum: 0),
  ),
  required-keys: ("name",),
)
#let bad-person = validate((name: "", age: -1), schema: person)
#assert.eq(bad-person.len(), 2)
#assert.eq(bad-person.at(0).path, ("name",))
#assert(bad-person.at(0).message.contains("≥ 1"))
#assert.eq(bad-person.at(1).path, ("age",))
#assert(bad-person.at(1).message.contains("≥ 0"))
