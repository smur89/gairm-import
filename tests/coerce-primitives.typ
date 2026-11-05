// _coerce on primitive schema nodes: content-type wraps the string
// into Typst content; everything else is identity.

#import "../lib.typ": coerce
#import "../lib.typ": (
  str-type, content-type, number-type, integer-type, date-string,
  datetime-string, uri-string, email-string, pattern-string,
)

#assert.eq(coerce("hi", schema: str-type), "hi")
#assert.eq(coerce(42, schema: number-type), 42)
#assert.eq(coerce(3.14, schema: number-type), 3.14)
// integer-type shares the number branch — validation owns the
// integral gate; coercion is identity.
#assert.eq(coerce(42, schema: integer-type), 42)

#let wrapped = coerce("summary text", schema: content-type)
#assert.eq(type(wrapped), content)

// Format-specialised string kinds pass through identically to `str` —
// the regex gate fires in _validate, not here, and the value flows
// through unchanged for downstream renderers.
#assert.eq(coerce("2024-01-15", schema: date-string), "2024-01-15")
#assert.eq(
  coerce("2024-01-15T10:00:00Z", schema: datetime-string),
  "2024-01-15T10:00:00Z",
)
#assert.eq(
  coerce("https://example.com", schema: uri-string),
  "https://example.com",
)
#assert.eq(coerce("name@example.com", schema: email-string), "name@example.com")
#assert.eq(coerce("US", schema: pattern-string("^[A-Z]{2}$")), "US")
