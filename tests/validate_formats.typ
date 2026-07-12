// Format-specialised string combinators reject malformed values and
// surface path-qualified messages with a canonical example. Coverage:
//
//  - date-string     → iso8601 (YYYY / YYYY-MM / YYYY-MM-DD)
//  - datetime-string → iso8601 datetime (date + T + HH:MM:SS, optional fractional + offset)
//  - uri-string      → scheme://rest (permissive)
//  - email-string    → local@domain.tld (permissive)

#import "../internal/validate.typ": _validate
#import "../internal/kinds.typ": (
  date-string, datetime-string, uri-string, email-string,
  object, array-of,
)

// ---- date-string ----------------------------------------------------

// All three iso8601 shapes the canonical schema accepts.
#assert.eq(_validate(date-string, "2024",       ("d",)), ())
#assert.eq(_validate(date-string, "2024-01",    ("d",)), ())
#assert.eq(_validate(date-string, "2024-01-15", ("d",)), ())
#assert.eq(_validate(date-string, "1999-12-31", ("d",)), ())

#let date-fail(value, path) = {
  let errs = _validate(date-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

// Slash-separated, free-text, partial, three-digit year, datetime
// forms — all rejected. The message names ISO-8601 and gives the
// canonical example.
#let m1 = date-fail("2024/01/15", ("basics", "startDate"))
#assert(m1.contains("ISO-8601"))
#assert(m1.contains("e.g. \"2024-01-15\""))

#assert(date-fail("jan 2024",   ("d",)).contains("ISO-8601"))
#assert(date-fail("2024-1-15",  ("d",)).contains("ISO-8601"))
#assert(date-fail("24-01-15",   ("d",)).contains("ISO-8601"))
#assert(date-fail("",           ("d",)).contains("ISO-8601"))
#assert(date-fail("2024-01-15T10:00", ("d",)).contains("ISO-8601"))

// Calendar-range tightening — the canonical schema regex accepts
// months 13-19 and days 32-39 because it uses [0-1][0-9] / [0-3][0-9].
// We constrain to real ranges (01-12 / 01-31). Day=00 and month=00
// are also rejected.
#assert(date-fail("2024-13-15", ("d",)).contains("ISO-8601"))  // month > 12
#assert(date-fail("2024-00-15", ("d",)).contains("ISO-8601"))  // month = 00
#assert(date-fail("2024-01-00", ("d",)).contains("ISO-8601"))  // day   = 00
#assert(date-fail("2024-01-32", ("d",)).contains("ISO-8601"))  // day  > 31

// Wrong type yields a type-error, not a format-error — the format gate
// only fires once we know we have a string.
#let date-type-err = _validate(date-string, 2024, ("d",))
#assert.eq(date-type-err.len(), 1)
#assert(date-type-err.at(0).message.contains("expected string"))
#assert(date-type-err.at(0).message.contains("got integer"))

// ---- datetime-string ------------------------------------------------

// Bare datetime (no fractional, no offset), with fractional, with `Z`,
// with `±HH:MM` offset — all accepted.
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00",         ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00.123",     ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00Z",        ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00.5Z",      ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00+01:00",   ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T10:00:00-05:30",   ("dt",)), ())
#assert.eq(_validate(datetime-string, "2024-01-15T23:59:59.999+14:00", ("dt",)), ())

#let datetime-fail(value, path) = {
  let errs = _validate(datetime-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

// Missing T separator, missing seconds, date-only — all rejected so a
// pure-date value can't quietly pass under a datetime-string gate.
#let m-dt = datetime-fail("2024-01-15 10:00:00", ("meta", "lastModified"))
#assert(m-dt.contains("ISO-8601 datetime"))
#assert(m-dt.contains("e.g. \"2024-01-15T10:00:00Z\""))

#assert(datetime-fail("2024-01-15",          ("dt",)).contains("ISO-8601 datetime"))  // no time
#assert(datetime-fail("2024-01-15T10:00",    ("dt",)).contains("ISO-8601 datetime"))  // no seconds
#assert(datetime-fail("2024-01-15T1:00:00",  ("dt",)).contains("ISO-8601 datetime"))  // 1-digit hour
#assert(datetime-fail("",                    ("dt",)).contains("ISO-8601 datetime"))

// Malformed timezones — anything other than `Z` or `±HH:MM`.
#assert(datetime-fail("2024-01-15T10:00:00+0100",   ("dt",)).contains("ISO-8601 datetime"))  // no colon
#assert(datetime-fail("2024-01-15T10:00:00+1:00",   ("dt",)).contains("ISO-8601 datetime"))  // 1-digit hour
#assert(datetime-fail("2024-01-15T10:00:00+25:00",  ("dt",)).contains("ISO-8601 datetime"))  // hour > 23
#assert(datetime-fail("2024-01-15T10:00:00z",       ("dt",)).contains("ISO-8601 datetime"))  // lowercase z
#assert(datetime-fail("2024-01-15T10:00:00UTC",     ("dt",)).contains("ISO-8601 datetime"))  // named tz

// Calendar / clock out-of-range — same tightening as date-string, plus
// hours/minutes/seconds.
#assert(datetime-fail("2024-13-15T10:00:00Z", ("dt",)).contains("ISO-8601 datetime"))  // month > 12
#assert(datetime-fail("2024-00-15T10:00:00Z", ("dt",)).contains("ISO-8601 datetime"))  // month = 00
#assert(datetime-fail("2024-01-00T10:00:00Z", ("dt",)).contains("ISO-8601 datetime"))  // day   = 00
#assert(datetime-fail("2024-01-32T10:00:00Z", ("dt",)).contains("ISO-8601 datetime"))  // day  > 31
#assert(datetime-fail("2024-01-15T24:00:00Z", ("dt",)).contains("ISO-8601 datetime"))  // hour = 24
#assert(datetime-fail("2024-01-15T10:60:00Z", ("dt",)).contains("ISO-8601 datetime"))  // minute = 60
#assert(datetime-fail("2024-01-15T10:00:60Z", ("dt",)).contains("ISO-8601 datetime"))  // second = 60

// Wrong type yields a type-error, not a format-error.
#let dt-type-err = _validate(datetime-string, 2024, ("dt",))
#assert.eq(dt-type-err.len(), 1)
#assert(dt-type-err.at(0).message.contains("expected string"))
#assert(dt-type-err.at(0).message.contains("got integer"))

// ---- uri-string -----------------------------------------------------

// uri-string is "scheme + `://` + rest" — the canonical `url` /
// `image` / `canonical` fields in JSON Resume are all http(s)-shaped,
// so opaque schemes like `mailto:` and `urn:` fall outside the gate
// by design. Promote later if a caller needs them.
#assert.eq(_validate(uri-string, "https://example.com",        ("u",)), ())
#assert.eq(_validate(uri-string, "http://example.com/path",    ("u",)), ())
#assert.eq(_validate(uri-string, "git+ssh://host/repo.git",    ("u",)), ())

// RFC 3986 declares schemes case-insensitive — uppercase and mixed-case
// schemes must validate.
#assert.eq(_validate(uri-string, "HTTP://example.com",  ("u",)), ())
#assert.eq(_validate(uri-string, "HTTPS://example.com", ("u",)), ())

#let uri-fail(value, path) = {
  let errs = _validate(uri-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

#let m2 = uri-fail("not-a-uri", ("basics", "url"))
#assert(m2.contains("URI"))
#assert(m2.contains("e.g. \"https://example.com\""))

#assert(uri-fail("example.com",     ("u",)).contains("URI"))
#assert(uri-fail("://example.com",  ("u",)).contains("URI"))
#assert(uri-fail("https://",        ("u",)).contains("URI"))
#assert(uri-fail("",                ("u",)).contains("URI"))

// Embedded whitespace — a space inside the rest is rejected so that a
// fat-finger like `https://example.com /cv` doesn't quietly pass.
#assert(uri-fail("https://example.com /cv", ("u",)).contains("URI"))

// ---- email-string ---------------------------------------------------

#assert.eq(_validate(email-string, "name@example.com",     ("e",)), ())
#assert.eq(_validate(email-string, "first.last@host.co.uk",("e",)), ())
#assert.eq(_validate(email-string, "user+tag@example.com", ("e",)), ())

#let email-fail(value, path) = {
  let errs = _validate(email-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

#let m3 = email-fail("name@", ("basics", "email"))
#assert(m3.contains("email"))
#assert(m3.contains("e.g. \"name@example.com\""))

#assert(email-fail("@example.com", ("e",)).contains("email"))
#assert(email-fail("name",         ("e",)).contains("email"))
#assert(email-fail("name@host",    ("e",)).contains("email"))  // no dot in domain
#assert(email-fail("a b@host.com", ("e",)).contains("email"))  // whitespace in local
#assert(email-fail("",             ("e",)).contains("email"))

// Empty labels in the domain — the previous pattern accepted these
// because a greedy `[^@\s]+\.[^@\s]+` split could absorb the second
// dot into one side. The per-label form rejects them.
#assert(email-fail("foo@bar..com", ("e",)).contains("email"))  // double dot
#assert(email-fail("foo@.com",     ("e",)).contains("email"))  // leading dot
#assert(email-fail("foo@host.",    ("e",)).contains("email"))  // trailing dot

// ---- Nested under array-of / object: paths stay correct -------------

#let _work = object((url: uri-string, startDate: date-string))
#let schema = object((work: array-of(_work), email: email-string))

#let nested-errs = _validate(
  schema,
  (
    work: (
      (url: "https://ok.example", startDate: "2024-01"),
      (url: "nope",                startDate: "2024/01/15"),
    ),
    email: "name@",
  ),
  (),
)
#assert.eq(nested-errs.len(), 3)

// Path-qualified errors are sorted by the validator's natural walk
// (per-key for the array element, then siblings). Spot-check each.
#let paths = nested-errs.map(e => e.path)
#assert(("work", 1, "url")       in paths)
#assert(("work", 1, "startDate") in paths)
#assert(("email",)               in paths)
