// The string formats and patterns: each kind takes the values of its
// format and rejects the rest with a path-qualified message naming it,
// the wrong type is a type error, and a format kind may carry an extra
// pattern. A date kind also takes a Typst datetime, checked and
// coerced as the ISO string it converts to.

#import "../lib.typ": (
  validate, coerce, parse, schema-from-json-schema, describe-schema,
  date-string, datetime-string, uri-string, email-string, uuid-string,
  hostname-string, ipv4-string, ipv6-string, time-string, pattern-string,
  object, array-of, resume-schema-strict,
)

// The errors for `value` at field `f`.
#let at(kind, value) = validate((f: value), schema: object((f: kind)))

#let country-code = pattern-string(
  "^[A-Z]{2}$",
  expected: "an ISO 3166-1 alpha-2 code",
)

// ---- what each kind takes and rejects --------------------------------
//
// Each row: the kind, the text its message names, values it takes, and
// values it rejects with one error at the field's path. Many cases are
// adapted from the JSON Schema test suite.

#for (kind, hint, good, bad) in (
  (
    date-string,
    "ISO-8601",
    // The three iso8601 shapes the canonical schema accepts.
    ("2024", "2024-01", "2024-01-15", "1999-12-31"),
    (
      "2024/01/15",
      "jan 2024",
      "2024-1-15",
      "24-01-15",
      "",
      "2024-01-15T10:00",
      // The canonical regex takes months 13-19 and days 32-39; these
      // are held to real ranges, and month or day 00 is rejected.
      "2024-13-15",
      "2024-00-15",
      "2024-01-00",
      "2024-01-32",
    ),
  ),
  (
    datetime-string,
    "ISO-8601 datetime",
    (
      "2024-01-15T10:00:00",
      "2024-01-15T10:00:00.123",
      "2024-01-15T10:00:00Z",
      "2024-01-15T10:00:00.5Z",
      "2024-01-15T10:00:00+01:00",
      "2024-01-15T10:00:00-05:30",
      "2024-01-15T23:59:59.999+14:00",
      // RFC 3339 allows a leap second and a lowercase `t` / `z`. Second
      // 60 only falls at minute 59, or any minute under an offset with
      // minutes (UTC 23:59:60 at +01:30 is 01:29:60).
      "1998-12-31T23:59:60Z",
      "1998-12-31T15:59:60.123-08:00",
      "1998-12-31T23:59:60+00:00",
      "1999-01-01T01:29:60+01:30",
      "1963-06-19t08:30:06.283185z",
      "2024-01-15T10:00:00z",
    ),
    (
      "2024-01-15 10:00:00", // no T
      "2024-01-15", // no time: a date can't pass as a datetime
      "2024-01-15T10:00", // no seconds
      "2024-01-15T1:00:00", // 1-digit hour
      "",
      // A timezone other than `Z` or `±HH:MM`.
      "2024-01-15T10:00:00+0100",
      "2024-01-15T10:00:00+1:00",
      "2024-01-15T10:00:00+25:00",
      "2024-01-15T10:00:00UTC",
      // Out of calendar or clock range.
      "2024-13-15T10:00:00Z",
      "2024-00-15T10:00:00Z",
      "2024-01-00T10:00:00Z",
      "2024-01-32T10:00:00Z",
      "2024-01-15T24:00:00Z",
      "2024-01-15T10:60:00Z",
      "2024-01-15T10:00:60Z", // second 60 off a leap-second minute
      "1998-12-31T23:58:60Z",
      "1998-12-31T23:59:61Z",
    ),
  ),
  (
    uri-string,
    "URI",
    // Any scheme, hierarchical or opaque, case-insensitive (RFC 3986),
    // then no whitespace.
    (
      "https://example.com",
      "http://example.com/path",
      "git+ssh://host/repo.git",
      "HTTP://example.com",
      "HTTPS://example.com",
      "mailto:John.Doe@example.com",
      "urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
      "tel:+1-816-555-1212",
      "news:comp.infosystems.www.servers.unix",
      "ldap://[2001:db8::7]/c=GB?objectClass?one",
      "file:///etc/hosts",
    ),
    (
      "not-a-uri",
      "example.com",
      "://example.com",
      "https://",
      "",
      "https://example.com /cv", // embedded whitespace
      "mailto:a b@example.com",
      "bar,baz:foo", // bad scheme
      "/abc", // relative, no scheme
    ),
  ),
  (
    email-string,
    "email",
    // A single-label domain, a quoted local part and an IP-literal
    // domain are valid (RFC 5321).
    (
      "name@example.com",
      "first.last@host.co.uk",
      "user+tag@example.com",
      "test@io",
      "name@host",
      "\"joe bloggs\"@example.com",
      "\"joe@bloggs\"@example.com",
      "joe.bloggs@[127.0.0.1]",
      "joe.bloggs@[IPv6:::1]",
    ),
    (
      "name@",
      "@example.com",
      "name",
      "a b@host.com", // whitespace in the local part
      "\"a b@host.com", // unclosed quote
      "a@[1.2.3.4", // unclosed literal
      "",
      // Empty domain labels.
      "foo@bar..com",
      "foo@.com",
      "foo@host.",
    ),
  ),
  (
    uuid-string,
    "a UUID",
    (
      "123e4567-e89b-12d3-a456-426614174000",
      "123E4567-E89B-12D3-A456-426614174000",
    ),
    (
      "",
      "123e4567e89b12d3a456426614174000",
      "123e4567-e89b-12d3-a456-42661417400",
      "123e4567-e89b-12d3-a456-4266141740000",
      "123e4567-e89b-12d3-a456-42661417400g",
      "{123e4567-e89b-12d3-a456-426614174000}",
    ),
  ),
  (
    hostname-string,
    "a hostname",
    (
      "example.com",
      "localhost",
      "a-b.c-d.example.org",
      "EXAMPLE.COM",
      "1host.io",
    ),
    (
      "",
      "-bad.com",
      "bad-.com",
      "bad..com",
      ".bad.com",
      "bad.com.",
      "has space.com",
      "under_score.com",
      "http://example.com",
      "a" * 64 + ".com",
    ),
  ),
  (
    ipv4-string,
    "an IPv4 address",
    ("192.0.2.1", "0.0.0.0", "255.255.255.255", "10.0.0.1"),
    (
      "",
      "256.0.0.1",
      "1.2.3",
      "1.2.3.4.5",
      "01.2.3.4",
      "1.2.3.-4",
      "1.2.3.4 ",
      "a.b.c.d",
    ),
  ),
  (
    ipv6-string,
    "an IPv6 address",
    (
      "2001:db8:0:0:0:0:0:1",
      "2001:db8::1",
      "::1",
      "::",
      "fe80::",
      "1::",
      "1:2:3:4:5:6:7::",
      "::2:3:4:5:6:7:8",
      "2001:DB8::ff00:42:8329",
      "1:2:3:4:5:6:7:8",
    ),
    (
      "",
      ":",
      ":::",
      "1::2::3",
      "12345::1",
      "2001:db8:::1",
      "1:2:3:4:5:6:7",
      "1:2:3:4:5:6:7:8:9",
      "1:2:3:4:5:6:7:8::",
      "g::1",
      "::1 ",
      "192.0.2.1",
    ),
  ),
  (
    time-string,
    "an ISO-8601 time",
    (
      "10:00:00",
      "10:00:00Z",
      "00:00:00.5Z",
      "23:59:59.999+14:00",
      "10:00:00-05:30",
      // Leap second and lowercase `z`, as for datetime-string.
      "23:59:60Z",
      "23:59:60",
      "15:59:60.5-08:00",
      "01:29:60+01:30",
      "10:00:00z",
    ),
    (
      "",
      "10:00",
      "1:00:00",
      "24:00:00",
      "10:60:00",
      "10:00:60",
      "23:58:60Z",
      "23:59:61Z",
      "10:00:00+0100",
      "10:00:00.Z",
      "2024-01-15T10:00:00Z",
    ),
  ),
  // A pattern applies as authored: Typst's `match` is substring-based,
  // so anchoring is the schema author's job.
  (
    country-code,
    "ISO 3166-1 alpha-2 code",
    ("US", "IE"),
    ("USA", "us", "", "U1"),
  ),
  (
    pattern-string("[0-9]", expected: "a string containing a digit"),
    "digit",
    ("abc123", "1", "v2-final"),
    ("no-digits-here",),
  ),
  // Without `expected`, the message names the pattern.
  (pattern-string("^x$"), "matching pattern", ("x",), ("y",)),
) {
  for v in good {
    assert.eq(at(kind, v), (), message: "expected valid: " + repr(v))
  }
  for v in bad {
    let errs = at(kind, v)
    assert.eq(errs.len(), 1, message: "expected one error for " + repr(v))
    assert.eq(errs.at(0).path, ("f",))
    assert(errs.at(0).message.contains(hint), message: repr(v))
  }
}

// The message gives a canonical example.
#for (kind, value, example) in (
  (date-string, "2024/01/15", "2024-01-15"),
  (datetime-string, "2024-01-15 10:00:00", "2024-01-15T10:00:00Z"),
  (uri-string, "not-a-uri", "https://example.com"),
  (email-string, "name@", "name@example.com"),
) {
  assert(at(kind, value).at(0).message.contains("e.g. \"" + example + "\""))
}

// The wrong type is a type error, not a format or pattern one: those
// gates fire only on a string.
#for kind in (date-string, datetime-string, country-code) {
  let errs = at(kind, 2024)
  assert.eq(errs.len(), 1)
  assert(errs.at(0).message.contains("expected string, got integer"))
}

// Nested under array-of / object, paths stay correct.
#let nested-errs = validate(
  (
    work: (
      (url: "https://ok.example", startDate: "2024-01"),
      (url: "nope", startDate: "2024/01/15"),
    ),
    email: "name@",
    codes: ("US", "usa", "IE"),
  ),
  schema: object((
    work: array-of(object((url: uri-string, startDate: date-string))),
    email: email-string,
    codes: array-of(country-code),
  )),
)
#assert.eq(nested-errs.map(e => e.path), (
  ("work", 1, "url"),
  ("work", 1, "startDate"),
  ("email",),
  ("codes", 1),
))

// A regex value works where a pattern string does (#135).
#let by-regex = pattern-string(regex("^[A-Z]{3}$"))
#assert.eq(at(by-regex, "ABC"), ())
#assert.eq(at(by-regex, "abc").len(), 1)

// Format kinds coerce as the string they are.
#for (kind, value) in (
  (date-string, "2024-01-15"),
  (datetime-string, "2024-01-15T10:00:00Z"),
  (uri-string, "https://example.com"),
  (email-string, "name@example.com"),
  (pattern-string("^[A-Z]{2}$"), "US"),
) {
  assert.eq(coerce(value, schema: kind), value)
}

// ---- a format with a pattern -----------------------------------------
//
// JSON Schema `format` + `pattern` (#115): both gates apply, the format
// first.

#let example-email = schema-from-json-schema((
  type: "string",
  format: "email",
  pattern: "@example\\.com$",
))
#assert.eq(validate("a@example.com", schema: example-email), ())
// Passes the format, fails the pattern.
#let errs = validate("a@other.org", schema: example-email)
#assert.eq(errs.len(), 1)
#assert(errs.first().message.contains("matching"))
// Fails the format (the pattern alone would match): the format error.
#let errs = validate("@example.com", schema: example-email)
#assert.eq(errs.len(), 1)
#assert(not errs.first().message.contains("matching"))

// A hand-built node may carry `pattern` without `expected`.
#let bare = (kind: "email-string", pattern: regex("@example\\.com$"))
#assert.eq(validate("a@example.com", schema: bare), ())
#assert.eq(
  validate("a@other.org", schema: bare).first().message,
  "expected matching pattern.",
)

// describe-schema flags the extra gate.
#assert(
  describe-schema(object((e: example-email))).contains(
    "email-string + pattern",
  ),
)

// ---- a datetime for a date kind ----------------------------------------
//
// Data written in Typst may give a date kind a datetime (#134).

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

// The right shapes validate and coerce to ISO strings.
#assert.eq(validate((d: day, dt: moment), schema: schema), ())
#assert.eq(
  coerce((d: day, dt: moment), schema: schema),
  (d: "2024-01-05", dt: "2024-01-05T09:03:07"),
)

// The wrong shapes are rejected, never truncated.
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
#assert.eq(
  validate((d: datetime(hour: 9, minute: 3, second: 7)), schema: schema).len(),
  1,
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
#assert.eq(at((..date-string, max-length: 4), day).len(), 1)

// So does a pattern, and coerce passes the node through unchanged.
#let year = schema-from-json-schema((
  type: "string",
  format: "date",
  pattern: "^2024-",
))
#assert.eq(validate(day, schema: year), ())
#assert.eq(validate("2024-01-05", schema: year), ())
#assert.eq(
  validate(datetime(year: 2023, month: 1, day: 5), schema: year).len(),
  1,
)
#assert.eq(validate("2023-01-05", schema: year).len(), 1)
#assert.eq(coerce(day, schema: year), "2024-01-05")
