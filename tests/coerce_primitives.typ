// _coerce on primitive schema nodes: content-type wraps the string
// into Typst content; everything else is identity.

#import "../internal/coerce.typ": _coerce
#import "../internal/schema.typ": (
  str-type, content-type, number-type, date-string, uri-string, email-string,
)

#assert.eq(_coerce(str-type, "hi"), "hi")
#assert.eq(_coerce(number-type, 42), 42)
#assert.eq(_coerce(number-type, 3.14), 3.14)

#let wrapped = _coerce(content-type, "summary text")
#assert.eq(type(wrapped), content)

// Format-specialised string kinds pass through identically to `str` —
// the regex gate fires in _validate, not here, and the value flows
// through unchanged for downstream renderers.
#assert.eq(_coerce(date-string,  "2024-01-15"),          "2024-01-15")
#assert.eq(_coerce(uri-string,   "https://example.com"), "https://example.com")
#assert.eq(_coerce(email-string, "name@example.com"),    "name@example.com")
