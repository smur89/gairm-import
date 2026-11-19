// Mirrors REFERENCE.md, "Formats": the report its block shows for
// `member`, and the datetime values it says a date format takes. The
// report must match the block.
#import "@preview/gairm-import:0.0.0": validate, coerce, format-errors, string
#import "reference-schemas.typ": member

#assert.eq(
  format-errors(validate(member, (
    name: "Ada",
    email: "ada",
    homepage: "example.com",
    joined: "2024/01/15",
  ))),
  "gairm-import: found 3 problems in the input:
  - email: expected an email (e.g. \"name@example.com\").
  - homepage: expected a URI (e.g. \"https://example.com\").
  - joined: expected an RFC 3339 date (e.g. \"2024-01-15\").",
)

// A partial date, or a time with no offset, is not one of the formats.
#assert.eq(validate(string(format: "date"), "2024-01").len(), 1)
#assert.eq(validate(string(format: "time"), "10:00:00").len(), 1)

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
#assert.eq(validate(string(format: "date"), date-time).len(), 1)
#assert.eq(validate(string(format: "date-time"), date).len(), 1)
#assert.eq(validate(string(format: "date-time"), date-time).len(), 1)
