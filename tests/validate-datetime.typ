// Data written in Typst may give a date kind a datetime (#134). It is
// checked as the ISO string it converts to, and coerces to that string.

#import "../lib.typ": (
  validate, coerce, parse, object, date-string, datetime-string,
  resume-schema-strict,
)

#let schema = object((d: date-string, dt: datetime-string))
#let day = datetime(year: 2024, month: 1, day: 5)
#let moment = datetime(
  year: 2024,
  month: 1,
  day: 5,
  hour: 9,
  minute: 3,
  second: 7,
)
#let clock = datetime(hour: 9, minute: 3, second: 7)

// Right shapes validate and coerce to ISO strings.
#assert.eq(validate((d: day, dt: moment), schema: schema), ())
#assert.eq(
  coerce((d: day, dt: moment), schema: schema),
  (d: "2024-01-05", dt: "2024-01-05T09:03:07"),
)

// Wrong shapes are rejected, never truncated.
#let errs = validate((d: moment, dt: day), schema: schema)
#assert.eq(errs.map(e => e.path), (("d",), ("dt",)))
#assert.eq(
  errs.at(0).message,
  "expected a string or a datetime with a date and no time, got datetime.",
)
#assert.eq(
  errs.at(1).message,
  "expected a string or a datetime with a date and a time, got datetime.",
)
#assert.eq(validate((d: clock), schema: schema).len(), 1)

// Other non-strings keep the existing message.
#assert.eq(
  validate((d: 1), schema: schema).at(0).message,
  "expected string, got integer.",
)

// Strict meta.lastModified is any-of((datetime-string, date-string)):
// both datetime shapes land.
#assert.eq(
  parse((meta: (lastModified: moment)), schema: resume-schema-strict),
  (meta: (lastModified: "2024-01-05T09:03:07")),
)
#assert.eq(
  parse((meta: (lastModified: day)), schema: resume-schema-strict),
  (meta: (lastModified: "2024-01-05")),
)

// Length keywords see the converted string.
#let short = object((d: (..date-string, max-length: 4)))
#assert.eq(validate((d: day), schema: short).len(), 1)
