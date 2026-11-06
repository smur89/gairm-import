// The constructors build plain schema nodes. string(), number(),
// integer() and array-of() take constraint arguments (#162): the
// constants are their no-argument values, each argument sets the field
// the translator sets for its JSON keyword, and the result validates as
// that node does.

#import "../lib.typ": (
  string, number, integer, array-of, str-type, number-type, integer-type,
  email-string, date-string, datetime-string, uri-string, uuid-string,
  hostname-string, ipv4-string, ipv6-string, time-string, pattern-string,
  schema-from-json-schema, validate, coerce, object, paths-of-kind,
  content-type, any-of,
)

// ---- the nodes ---------------------------------------------------------

#assert.eq(str-type, (kind: "string"))
#assert.eq(content-type, (kind: "content"))
#assert.eq(number-type, (kind: "number"))
#assert.eq(array-of(str-type), (kind: "array", elem: (kind: "string")))
#assert.eq(
  object((name: str-type, age: number-type)),
  (
    kind: "object",
    shape: (name: (kind: "string"), age: (kind: "number")),
    required-keys: (),
  ),
)
#assert.eq(
  object((a: str-type, b: str-type), required-keys: ("a", "b")),
  (
    kind: "object",
    shape: (a: (kind: "string"), b: (kind: "string")),
    required-keys: ("a", "b"),
  ),
)

// A patterned string is the string kind with a `pattern` and the hint
// its error shows; pattern-string builds the same node.
#assert.eq(
  string(pattern: "^a", expected: "an a-word"),
  (kind: "string", pattern: regex("^a"), expected: "an a-word"),
)
#assert.eq(
  string(pattern: "^a"),
  (kind: "string", pattern: regex("^a"), expected: "matching pattern"),
)

// A formatted string is the string kind with a `format`, the JSON
// Schema format name; a pattern composes with it.
#assert.eq(string(format: "date"), (kind: "string", format: "date"))
#assert.eq(
  string(format: "date", pattern: "^2", expected: "this century"),
  (
    kind: "string",
    format: "date",
    pattern: regex("^2"),
    expected: "this century",
  ),
)

// A hand-built node of an old kind name, "str" or "pattern-string", is
// still a schema and checks as the string kind (deprecated, until 1.0);
// errors name it "string".
#let old-str = (kind: "str", min-length: 2)
#let old-pattern = (
  kind: "pattern-string",
  pattern: regex("^a"),
  expected: "an a-word",
)
#assert.eq(validate("ab", schema: old-str), ())
#assert.eq(validate("a", schema: old-str).map(e => e.code), ("length",))
#assert.eq(validate(1, schema: old-str).map(e => e.expected), ("string",))
#assert.eq(validate("b", schema: old-pattern).map(e => e.expected), (
  "an a-word",
))
#assert.eq(coerce((a: "ab"), schema: object((a: old-str))), (a: "ab"))
#assert.eq(
  validate(true, schema: any-of((old-pattern, number-type))).at(0).expected,
  "string | number",
)

// So is one of an old format kind name, as the string with that format,
// any other field kept: it validates, coerces and is reported as that
// string does.
#for (name, format, good, bad) in (
  ("date-string", "date", "2024-01-15", "2024/01/15"),
  ("datetime-string", "date-time", "2024-01-15T10:00:00Z", "2024-01-15"),
  ("uri-string", "uri", "https://example.com", "not-a-uri"),
  ("email-string", "email", "a@b.c", "name@"),
  ("uuid-string", "uuid", "123e4567-e89b-12d3-a456-426614174000", "123"),
  ("hostname-string", "hostname", "example.com", "-bad-"),
  ("ipv4-string", "ipv4", "192.0.2.1", "256.0.0.1"),
  ("ipv6-string", "ipv6", "2001:db8::1", "2001:::1"),
  ("time-string", "time", "10:00:00Z", "25:00:00"),
) {
  let old = (kind: name, max-length: 40)
  let new = string(format: format, max-length: 40)
  for value in (good, bad, 1, "x" * 41) {
    assert.eq(
      validate(value, schema: old),
      validate(value, schema: new),
      message: name,
    )
  }
  assert.eq(coerce(good, schema: old), good)
  assert.eq(
    validate(1, schema: any-of((old, number-type))),
    validate(1, schema: any-of((new, number-type))),
  )
  assert.eq(
    validate(true, schema: any-of((old, number-type))).at(0).expected,
    "string (" + format + ") | number",
  )
}

// ---- the constants are the no-argument values -------------------------

#assert.eq(string(), str-type)
#assert.eq(number(), number-type)
#assert.eq(integer(), integer-type)
#assert.eq(array-of(str-type, unique-items: false), array-of(str-type))

// ---- format: and pattern: ----------------------------------------------

#assert.eq(string(format: "email"), email-string)
#for (name, kind) in (
  date: date-string,
  date-time: datetime-string,
  uri: uri-string,
  email: email-string,
  uuid: uuid-string,
  hostname: hostname-string,
  ipv4: ipv4-string,
  ipv6: ipv6-string,
  time: time-string,
) {
  assert.eq(string(format: name), kind)
  assert.eq(
    string(format: name),
    schema-from-json-schema((type: "string", format: name)),
  )
}

#assert.eq(
  string(pattern: "^a", expected: "x"),
  pattern-string("^a", expected: "x"),
)
#assert.eq(string(pattern: regex("^a")), pattern-string(regex("^a")))
#assert.eq(string(pattern: "^a"), pattern-string("^a"))

// Both compose as the translator composes them: the format with an
// extra pattern gate.
#assert.eq(
  string(format: "email", pattern: "@example\\.com$", expected: "x"),
  (..email-string, pattern: regex("@example\\.com$"), expected: "x"),
)
#assert.eq(
  string(
    format: "email",
    pattern: "@example\\.com$",
    expected: "matching \"@example\\\\.com$\"",
  ),
  schema-from-json-schema((
    type: "string",
    format: "email",
    pattern: "@example\\.com$",
  )),
)
#assert.eq(
  string(pattern: "^a", expected: "matching \"^a\"", max-length: 3),
  schema-from-json-schema((type: "string", pattern: "^a", maxLength: 3)),
)

// ---- each argument sets the translator's field -------------------------

#assert.eq(
  string(min-length: 3),
  schema-from-json-schema((type: "string", minLength: 3)),
)
#assert.eq(
  string(max-length: 3),
  schema-from-json-schema((type: "string", maxLength: 3)),
)
// A whole-number float count reads as an int, as in the translator.
#assert.eq(string(min-length: 2.0), (kind: "string", min-length: 2))
#assert.eq(
  string(format: "date", max-length: 10),
  schema-from-json-schema((type: "string", format: "date", maxLength: 10)),
)
#for (field, json, v) in (
  ("minimum", "minimum", 1),
  ("maximum", "maximum", 1.5),
  ("exclusive-minimum", "exclusiveMinimum", -2),
  ("exclusive-maximum", "exclusiveMaximum", 2),
  ("multiple-of", "multipleOf", 0.5),
) {
  assert.eq(
    number(..((field): v)),
    schema-from-json-schema((type: "number", (json): v)),
  )
  assert.eq(
    integer(..((field): v)),
    schema-from-json-schema((type: "integer", (json): v)),
  )
}
#for (field, json, v) in (
  ("min-items", "minItems", 1),
  ("max-items", "maxItems", 4),
  ("unique-items", "uniqueItems", true),
  ("unique-items", "uniqueItems", false),
) {
  assert.eq(
    array-of(str-type, ..((field): v)),
    schema-from-json-schema((
      type: "array",
      items: (type: "string"),
      (json): v,
    )),
  )
}

// ---- validation through a constructed schema ---------------------------

// Each row: a value, a constructed schema, and the codes validate
// reports.
#for (value, schema, codes) in (
  ("ab", string(min-length: 3), ("length",)),
  ("abc", string(min-length: 3), ()),
  ("x@y", string(format: "date"), ("format",)),
  ("b", string(pattern: "^a"), ("pattern",)),
  (0, number(minimum: 1), ("range",)),
  (1, number(exclusive-minimum: 1), ("range",)),
  (3, number(multiple-of: 2), ("multiple",)),
  (1.5, number(minimum: 1), ()),
  (1.5, integer(minimum: 1), ("integer",)),
  (0.5, integer(minimum: 1), ("integer", "range")),
  (("a",), array-of(str-type, min-items: 2), ("items",)),
  (("a", "a"), array-of(str-type, unique-items: true), ("unique",)),
) {
  assert.eq(
    validate(value, schema: schema).map(e => e.code),
    codes,
    message: repr(value),
  )
}
#assert.eq(
  validate("abcd", schema: string(max-length: 3)).at(0).message,
  "expected string length ≤ 3, got 4.",
)
#assert.eq(
  validate("b", schema: string(pattern: "^a", expected: "an a-word")),
  (
    (
      path: (),
      code: "pattern",
      message: "expected an a-word.",
      expected: "an a-word",
      got: "b",
    ),
  ),
)
#assert.eq(coerce(("a", "b"), schema: array-of(str-type, max-items: 2)), (
  "a",
  "b",
))

// A constrained node is still found by its kind, and a formatted
// string is a string.
#let s = object((
  name: string(min-length: 1),
  age: integer(minimum: 0),
  mail: string(format: "email", max-length: 254),
))
#assert.eq(paths-of-kind(s, str-type), (("mail",), ("name",)))
#assert.eq(paths-of-kind(s, integer-type), (("age",),))
#assert.eq(paths-of-kind(s, email-string), (("mail",),))
