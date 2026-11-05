// Every validation error carries a `code`, plus `expected` and `got`
// holding the raw data behind its message. One check per code.

#import "../lib.typ": (
  validate, str-type, number-type, integer-type, bool-type, null-type, array-of,
  object, enum-of, any-of, one-of, not-of, date-string, email-string,
  pattern-string,
)

// The one error `validate` reports, checked field by field.
#let check(errs, code, path, expected: none, got: none) = {
  assert.eq(errs.len(), 1, message: repr(errs))
  let e = errs.first()
  assert.eq(e.keys().sorted(), ("code", "expected", "got", "message", "path"))
  assert.eq(e.code, code)
  assert.eq(e.path, path)
  assert.eq(e.expected, expected)
  assert.eq(e.got, got)
}

// ---- type ---------------------------------------------------------------

#check(
  validate((a: 1), schema: object((a: str-type))),
  "type",
  ("a",),
  expected: "string",
  got: "integer",
)
#check(
  validate("x", schema: number-type),
  "type",
  (),
  expected: "number",
  got: "string",
)
#check(
  validate(1, schema: bool-type),
  "type",
  (),
  expected: "boolean",
  got: "integer",
)
#check(
  validate(1, schema: null-type),
  "type",
  (),
  expected: "null",
  got: "integer",
)
#check(
  validate(1, schema: array-of(str-type)),
  "type",
  (),
  expected: "array",
  got: "integer",
)
#check(
  validate(1, schema: object((:))),
  "type",
  (),
  expected: "object",
  got: "integer",
)
#check(
  validate(1, schema: email-string),
  "type",
  (),
  expected: "string",
  got: "integer",
)
// An enum none of whose values shares the value's type: the JSON type
// names its values have.
#check(
  validate(true, schema: enum-of(("a", "b"))),
  "type",
  (),
  expected: "string",
  got: "boolean",
)
// A union none of whose members takes the value's type.
#check(
  validate(true, schema: any-of((str-type, number-type))),
  "type",
  (),
  expected: "str | number",
  got: "boolean",
)

// ---- required -----------------------------------------------------------

#check(
  validate((:), schema: object((a: str-type), required-keys: ("a",))),
  "required",
  ("a",),
)

// ---- unknown-key --------------------------------------------------------

#check(
  validate((b: 1), schema: object((a: str-type, c: str-type))),
  "unknown-key",
  ("b",),
  expected: ("a", "c"),
  got: "b",
)

// ---- dependent ----------------------------------------------------------

#check(
  validate(
    (a: "x"),
    schema: object((a: str-type, b: str-type), dependent-required: (a: ("b",))),
  ),
  "dependent",
  (),
  expected: "b",
  got: "a",
)

// ---- enum ---------------------------------------------------------------

#check(
  validate("c", schema: enum-of(("a", "b"))),
  "enum",
  (),
  expected: ("a", "b"),
  got: "c",
)
// int and float are one JSON number type, so 2.5 is an enum miss.
#check(
  validate(2.5, schema: enum-of((1, 2))),
  "enum",
  (),
  expected: (1, 2),
  got: 2.5,
)

// ---- format -------------------------------------------------------------

#check(
  validate("nope", schema: email-string),
  "format",
  (),
  expected: "an email (e.g. \"name@example.com\")",
  got: "nope",
)
// A datetime that can't be written as a date is a format failure, not a
// type one: the kind takes datetimes.
#let clock = datetime(hour: 10, minute: 0, second: 0)
#check(
  validate(clock, schema: date-string),
  "format",
  (),
  expected: "a string or a datetime with a date and no time",
  got: clock,
)

// ---- pattern ------------------------------------------------------------

#check(
  validate("abc", schema: pattern-string("^[0-9]+$", expected: "digits")),
  "pattern",
  (),
  expected: "digits",
  got: "abc",
)
#check(
  validate("a@b.com", schema: (
    ..email-string,
    pattern: regex("^z"),
    expected: "a z-address",
  )),
  "pattern",
  (),
  expected: "a z-address",
  got: "a@b.com",
)

// ---- length -------------------------------------------------------------

#check(
  validate("ab", schema: (kind: "str", min-length: 3)),
  "length",
  (),
  expected: (min-length: 3),
  got: 2,
)
#check(
  validate("abcd", schema: (kind: "str", max-length: 3)),
  "length",
  (),
  expected: (max-length: 3),
  got: 4,
)

// ---- range --------------------------------------------------------------

#check(
  validate(0, schema: (kind: "number", minimum: 1)),
  "range",
  (),
  expected: (minimum: 1),
  got: 0,
)
#check(
  validate(5, schema: (kind: "number", maximum: 4)),
  "range",
  (),
  expected: (maximum: 4),
  got: 5,
)
#check(
  validate(1, schema: (kind: "number", exclusive-minimum: 1)),
  "range",
  (),
  expected: (exclusive-minimum: 1),
  got: 1,
)
#check(
  validate(4, schema: (kind: "number", exclusive-maximum: 4)),
  "range",
  (),
  expected: (exclusive-maximum: 4),
  got: 4,
)
// The same bound under minimum and exclusive-minimum: the record says
// which, not just the number.
#let at-least = validate(0.5, schema: (kind: "number", minimum: 1)).first()
#let above = validate(0.5, schema: (
  kind: "number",
  exclusive-minimum: 1,
)).first()
#assert.eq(at-least.expected, (minimum: 1))
#assert.eq(above.expected, (exclusive-minimum: 1))
#assert.ne(at-least.expected, above.expected)

// ---- multiple -----------------------------------------------------------

#check(
  validate(7, schema: (kind: "number", multiple-of: 3)),
  "multiple",
  (),
  expected: (multiple-of: 3),
  got: 7,
)

// ---- integer ------------------------------------------------------------

#check(
  validate((n: 1.5), schema: object((n: integer-type))),
  "integer",
  ("n",),
  got: 1.5,
)

// ---- items --------------------------------------------------------------

#check(
  validate((1,), schema: (..array-of(number-type), min-items: 2)),
  "items",
  (),
  expected: (min-items: 2),
  got: 1,
)
#check(
  validate((1, 2, 3), schema: (..array-of(number-type), max-items: 2)),
  "items",
  (),
  expected: (max-items: 2),
  got: 3,
)

// ---- unique -------------------------------------------------------------

#check(
  validate((1, 2, 1), schema: (..array-of(number-type), unique-items: true)),
  "unique",
  (),
  got: (0, 2),
)

// ---- union --------------------------------------------------------------

// Several members claim a string; none matches.
#check(
  validate("x", schema: any-of((enum-of(("a",)), email-string))),
  "union",
  (),
  expected: ("enum", "email-string"),
)
// one-of with more than one match.
#check(
  validate(1, schema: one-of((number-type, enum-of((1, 2))))),
  "union",
  (),
  expected: ("number", "enum"),
)

// ---- not ----------------------------------------------------------------

#check(validate("x", schema: not-of(str-type)), "not", ())

// ---- union claiming reads the type code ---------------------------------

// The enum takes strings, not bools: no member claims `true`.
#let letter-or-num = any-of((enum-of(("a", "b")), number-type))
#assert.eq(validate(true, schema: letter-or-num).first().code, "type")
// A string is claimed by the enum alone, which reports its own error.
#assert.eq(validate("c", schema: letter-or-num).first().code, "enum")
// A float on an integer member is still claimed: `integer`, not `type`.
#let int-or-str = any-of((integer-type, pattern-string("^a")))
#check(validate(1.5, schema: int-or-str), "integer", (), got: 1.5)
// A type error below the union's own path doesn't stop a member claiming.
#let obj-or-num = any-of((object((a: str-type)), number-type))
#check(
  validate((a: 1), schema: obj-or-num),
  "type",
  ("a",),
  expected: "string",
  got: "integer",
)
