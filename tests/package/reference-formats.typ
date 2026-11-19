// Mirrors REFERENCE.md, "Formats": the messages its block shows for
// `member`, and the datetime values it says a date format takes. The
// paths and messages must match the block.
#import "@preview/gairm-import:0.0.0": validate, coerce, string
#import "reference-schemas.typ": member

#assert.eq(
  validate(member, (
    name: "Ada",
    email: "ada",
    homepage: "example.com",
    joined: "2024/01/15",
  )).map(e => (e.path, e.message)),
  (
    (("email",), "expected an email (e.g. \"name@example.com\")."),
    (("homepage",), "expected a URI (e.g. \"https://example.com\")."),
    (("joined",), "expected an ISO-8601 date (e.g. \"2024-01-15\")."),
  ),
)

#let date = datetime(year: 2024, month: 1, day: 5)
#let date-time = datetime(
  year: 2024,
  month: 1,
  day: 5,
  hour: 9,
  minute: 3,
  second: 7,
)
#assert.eq(coerce(string(format: "date"), date), "2024-01-05")
#assert.eq(
  coerce(string(format: "date-time"), date-time),
  "2024-01-05T09:03:07",
)
#assert.eq(validate(string(format: "date"), date-time).len(), 1)
#assert.eq(validate(string(format: "date-time"), date).len(), 1)
