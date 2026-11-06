// Mirrors README.md, "Building a schema in Typst". The import and the
// schema match the README; the asserts are ours.
#import "@preview/gairm-import:0.0.0": object, array-of, string, number, integer

#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
  ),
  required-keys: ("name", "email"),
)

#import "@preview/gairm-import:0.0.0": (
  validate, str-type, number-type, integer-type, email-string, pattern-string,
)

#assert.eq(string(), str-type)
#assert.eq(number(), number-type)
#assert.eq(integer(), integer-type)
#assert.eq(string(format: "email"), email-string)
#assert.eq(
  string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
  pattern-string("^[A-Z]{3}$", expected: "a three-letter code"),
)

#assert.eq(
  validate(
    (
      name: "Aoife",
      email: "aoife@example.com",
      code: "ABC",
      age: 30,
      rating: 4.5,
      tags: ("a", "b"),
    ),
    schema: member,
  ),
  (),
)
#assert.eq(
  validate(
    (
      name: "",
      email: "aoife@example.com",
      code: "abc",
      age: 1.5,
      rating: 4.2,
      tags: ("a", "a"),
    ),
    schema: member,
  ).map(e => (e.path, e.code)),
  (
    (("name",), "length"),
    (("code",), "pattern"),
    (("age",), "integer"),
    (("rating",), "multiple"),
    (("tags",), "unique"),
  ),
)
