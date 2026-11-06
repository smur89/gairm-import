// Mirrors REFERENCE.md, "Formats": the messages its block shows under
// resume-schema-strict, and the datetime values it says a date format
// takes. The documents are ours; the paths and messages must match the
// block.
#import "@preview/gairm-import:0.0.0": (
  validate, coerce, resume-schema-strict, string,
)

#assert.eq(
  validate(
    (
      basics: (email: "name", url: "example.com"),
      certificates: ((date: "2024/01/15"),),
    ),
    schema: resume-schema-strict,
  ).map(e => (e.path, e.message)),
  (
    (("basics", "email"), "expected an email (e.g. \"name@example.com\")."),
    (("basics", "url"), "expected a URI (e.g. \"https://example.com\")."),
    (
      ("certificates", 0, "date"),
      "expected an ISO-8601 date (e.g. \"2024-01-15\").",
    ),
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
#assert.eq(coerce(date, schema: string(format: "date")), "2024-01-05")
#assert.eq(
  coerce(date-time, schema: string(format: "date-time")),
  "2024-01-05T09:03:07",
)
#assert.eq(validate(date-time, schema: string(format: "date")).len(), 1)
#assert.eq(validate(date, schema: string(format: "date-time")).len(), 1)
