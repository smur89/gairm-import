// A format kind with an extra pattern (JSON Schema `format` + `pattern`,
// #115): both gates apply, the format regex first, then the pattern.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, describe-schema, object,
)

#let email = schema-from-json-schema((
  type: "string",
  format: "email",
  pattern: "@example\\.com$",
))

#assert.eq(validate("a@example.com", schema: email), ())
// Passes the format, fails the pattern.
#let errs = validate("a@other.org", schema: email)
#assert.eq(errs.len(), 1)
#assert(errs.first().message.contains("matching"))
// Fails the format (the pattern alone would match), format error first.
#let errs = validate("@example.com", schema: email)
#assert.eq(errs.len(), 1)
#assert(not errs.first().message.contains("matching"))

// A hand-built node may carry `pattern` without `expected`.
#let bare = (kind: "email-string", pattern: regex("@example\\.com$"))
#assert.eq(validate("a@example.com", schema: bare), ())
#assert.eq(
  validate("a@other.org", schema: bare).first().message,
  "expected matching pattern.",
)

// The pattern also applies to the ISO string a datetime converts to.
#let year = schema-from-json-schema((
  type: "string",
  format: "date",
  pattern: "^2024-",
))
#assert.eq(validate(datetime(year: 2024, month: 1, day: 5), schema: year), ())
#assert.eq(validate("2024-01-05", schema: year), ())
#assert.eq(
  validate(datetime(year: 2023, month: 1, day: 5), schema: year).len(),
  1,
)
#assert.eq(validate("2023-01-05", schema: year).len(), 1)

// Coerce passes the node through unchanged.
#assert.eq(
  coerce(datetime(year: 2024, month: 1, day: 5), schema: year),
  "2024-01-05",
)

// describe-schema flags the extra gate.
#assert(describe-schema(object((e: email))).contains("email-string + pattern"))
