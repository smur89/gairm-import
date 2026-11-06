// Mirrors REFERENCE.md, "Constructors": the example schema, and the
// replacements "Deprecated names" gives for the constants. The import
// and the schema match REFERENCE.md; the asserts are ours.
#import "@preview/gairm-import:0.0.0": *

#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
    phone: string(),
  ),
  required-keys: ("name", "email"),
  dependent-required: (phone: ("email",)),
)

#assert.eq(string(), str-type)
#assert.eq(number(), number-type)
#assert.eq(integer(), integer-type)
#assert.eq(string(format: "email"), email-string)
#assert.eq(string(format: "date"), date-string)
#assert.eq(string(format: "date-time"), datetime-string)
#assert.eq(
  string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
  pattern-string("^[A-Z]{3}$", expected: "a three-letter code"),
)
#assert.eq(any-of(string(), number()), any-of((string(), number())))
#assert.eq(const-of(1), enum-of((1,)))

#assert.eq(
  validate(
    (
      name: "Aoife",
      email: "aoife@example.com",
      code: "ABC",
      age: 30,
      rating: 4.5,
      tags: ("a", "b"),
      phone: "555",
    ),
    schema: member,
  ),
  (),
)
#assert.eq(
  validate(
    (
      name: "",
      code: "abc",
      age: 1.5,
      rating: 4.2,
      tags: ("a", "a"),
      phone: "555",
    ),
    schema: member,
  )
    .map(e => (e.path, e.code))
    .sorted(),
  (
    (("age",), "integer"),
    (("code",), "pattern"),
    ((), "dependent"),
    (("email",), "required"),
    (("name",), "length"),
    (("rating",), "multiple"),
    (("tags",), "unique"),
  ).sorted(),
)
