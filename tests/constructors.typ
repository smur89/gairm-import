// The constructors build plain schema nodes. string(), number(),
// integer() and array-of() take constraint arguments (#162): the
// constants are their no-argument values, each argument sets the field
// the translator sets for its JSON keyword, and the result validates as
// that node does.

#import "../lib.typ": (
  string, number, integer, array-of, schema-from-json-schema, validate, coerce,
  object, paths-of-kind, content-type, any-of, if-of,
)

// ---- the nodes ---------------------------------------------------------

#assert.eq(string(), (kind: "string"))
#assert.eq(content-type, (kind: "content"))
#assert.eq(number(), (kind: "number"))
#assert.eq(array-of(string()), (kind: "array", elem: (kind: "string")))
#assert.eq(
  object((name: string(), age: number())),
  (
    kind: "object",
    shape: (name: (kind: "string"), age: (kind: "number")),
    required-keys: (),
  ),
)
#assert.eq(
  object((a: string(), b: string()), required-keys: ("a", "b")),
  (
    kind: "object",
    shape: (a: (kind: "string"), b: (kind: "string")),
    required-keys: ("a", "b"),
  ),
)
// A conditional stores the branches it has, `else` as `otherwise`.
#assert.eq(
  if-of(string(), then: number()),
  (kind: "if", cond: (kind: "string"), then: (kind: "number")),
)
#assert.eq(
  if-of(string(), otherwise: number()),
  (kind: "if", cond: (kind: "string"), otherwise: (kind: "number")),
)

// A patterned string is the string kind with a `pattern` and the hint
// its error shows.
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

// An unset argument adds no field.
#assert.eq(string(), (kind: "string"))
#assert.eq(number(), (kind: "number"))
#assert.eq(integer(), (kind: "integer"))
#assert.eq(array-of(string(), unique-items: false), array-of(string()))

// ---- format: and pattern: ----------------------------------------------

#for name in (
  "date",
  "date-time",
  "uri",
  "email",
  "uuid",
  "hostname",
  "ipv4",
  "ipv6",
  "time",
) {
  assert.eq(
    string(format: name),
    schema-from-json-schema((type: "string", format: name)),
  )
}

// A pattern string compiles to the regex it spells.
#assert.eq(string(pattern: "^a"), string(pattern: regex("^a")))

// Both compose as the translator composes them: the format with an
// extra pattern gate.
#assert.eq(
  string(format: "email", pattern: "@example\\.com$", expected: "x"),
  (..string(format: "email"), pattern: regex("@example\\.com$"), expected: "x"),
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
    array-of(string(), ..((field): v)),
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
  (("a",), array-of(string(), min-items: 2), ("items",)),
  (("a", "a"), array-of(string(), unique-items: true), ("unique",)),
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
#assert.eq(coerce(("a", "b"), schema: array-of(string(), max-items: 2)), (
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
#assert.eq(paths-of-kind(s, string()), (("mail",), ("name",)))
#assert.eq(paths-of-kind(s, integer()), (("age",),))
#assert.eq(paths-of-kind(s, string(format: "email")), (("mail",),))
