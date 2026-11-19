// Mirrors REFERENCE.md, "Constructors": the example schema. The import
// and the schema match REFERENCE.md; the asserts are ours.
#import "@preview/gairm-import:0.0.0": *

#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    homepage: string(format: "uri"),
    joined: string(format: "date"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
    phone: string(),
  ),
  required-keys: ("name", "email"),
  dependent-required: (phone: ("email",)),
)

// The schema above must be the one the other mirrors import.
#import "reference-schemas.typ" as shared
#assert.eq(member, shared.member)

#assert.eq(any-of(string(), number()), any-of((string(), number())))
#assert.eq(const-of(1), enum-of((1,)))

// The if-of example.
#let long-x = if-of(string(min-length: 5), then: string(pattern: "^x"))
#assert.eq(validate(long-x, "abc"), ())
#assert.eq(validate(long-x, "xyzzy"), ())
#assert.eq(validate(long-x, "abcde").map(e => e.code), ("pattern",))

#assert.eq(
  validate(member, (
    name: "Aoife",
    email: "aoife@example.com",
    homepage: "https://aoife.example",
    joined: "2024-01-15",
    code: "ABC",
    age: 30,
    rating: 4.5,
    tags: ("a", "b"),
    phone: "555",
  )),
  (),
)
#assert.eq(
  validate(member, (
    name: "",
    code: "abc",
    age: 1.5,
    rating: 4.2,
    tags: ("a", "a"),
    phone: "555",
  ))
    .map(e => (e.path, e.code))
    .sorted(),
  (
    (("age",), "integer"),
    (("code",), "pattern"),
    (("email",), "required"),
    (("name",), "length"),
    (("rating",), "multiple"),
    (("tags",), "unique"),
  ).sorted(),
)
