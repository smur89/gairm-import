// The string formats, one row each. A row is everything the package
// knows about a format: its kind, its JSON Schema `format` name, the
// regex that gates it, the hint an error shows, and whether a Typst
// `datetime` is accepted for it (none: no; false: a date with no time;
// true: a date and a time). The engine, the translator and
// introspection all read this table, so adding a format is one row,
// one constant below and one export in lib.typ.

#import "../core/error.typ": (
  _error, _expected-got, _type-miss, _type-name-of, _problem, _fail,
)
#import "leaf.typ": str-type, pattern-string, _pattern-errors
#import "constraint.typ": _constrain

// IPv6 is spelled as the eight-group form plus each place a single `::`
// can sit: `h` is one 1-4 digit hex group, and every alternative below
// is "n groups, `::`, m groups" with n + m <= 7. Embedded-IPv4 tails
// (`::ffff:1.2.3.4`) are not accepted.
#let _hex-group = "[0-9A-Fa-f]{1,4}"
#let _ipv6-pattern = {
  let h = _hex-group
  let alternatives = (
    h + "(?::" + h + "){7}",
    "(?:" + h + ":){1,7}:",
    "(?:" + h + ":){1,6}:" + h,
    // Up to n groups, `::`, up to 7 - n groups, for n = 2..5.
    ..range(2, 6).map(n => (
      "(?:" + h + ":){1," + str(n) + "}(?::" + h + "){1," + str(7 - n) + "}"
    )),
    h + ":(?::" + h + "){1,6}",
    ":(?::" + h + "){1,7}",
    "::",
  )
  "^(?:" + alternatives.join("|") + ")$"
}

// One DNS label (1-63 characters, no leading or trailing hyphen) and one
// IPv4 octet (0-255, no leading zeros), each used twice below.
#let _label = "[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
#let _octet = "(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])"

// A time of day, `HH:MM:SS` with an optional fraction and offset, as in
// RFC 3339: `Z` may be lowercase, and second 60 (a leap second) is let
// through where one can fall — at minute 59, or at any minute under an
// offset with minutes (UTC 23:59:60 at +01:30 is 01:29:60). Which hour
// is not checked.
#let _clock = {
  let hour = "([01][0-9]|2[0-3])"
  let fraction = "(\.[0-9]+)?"
  let offset-hour = "[+-]([01][0-9]|2[0-3]):"
  let offset = "([Zz]|" + offset-hour + "[0-5][0-9])"
  (
    "(?:"
      + hour
      + ":([0-5][0-9]:[0-5][0-9]|59:60)"
      + fraction
      + offset
      + "?|"
      + hour
      + ":[0-5][0-9]:60"
      + fraction
      + offset-hour
      + "(0[1-9]|[1-5][0-9]))"
  )
}

// Tightened over the upstream JSON Resume regexes, which accept
// impossible months / days because they use [0-1][0-9] / [0-3][0-9].
// Deliberately permissive (no full RFC compliance). The hint omits the
// offending value — the path already names the field, the canonical
// example is the actionable part.
#let _format-rows = (
  (
    kind: "date-string",
    json-schema: "date",
    datetime: false,
    pattern: regex(
      "^([0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])|[0-9]{4}-(0[1-9]|1[0-2])|[0-9]{4})$",
    ),
    expected: "an ISO-8601 date (e.g. \"2024-01-15\")",
  ),
  (
    kind: "datetime-string",
    json-schema: "date-time",
    datetime: true,
    pattern: regex(
      "^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])[Tt]" + _clock + "$",
    ),
    expected: "an ISO-8601 datetime (e.g. \"2024-01-15T10:00:00Z\")",
  ),
  (
    kind: "uri-string",
    json-schema: "uri",
    datetime: none,
    // Any scheme, then no whitespace; a `//` authority must not be
    // empty, so `https://` alone still fails.
    pattern: regex("^[A-Za-z][A-Za-z0-9+.\-]*:(//\S+|/?[^/\s]\S*)$"),
    expected: "a URI (e.g. \"https://example.com\")",
  ),
  (
    kind: "email-string",
    json-schema: "email",
    datetime: none,
    // An unquoted local part without whitespace, or a quoted one; a domain of one or
    // more labels, or an address literal in brackets (`[127.0.0.1]`,
    // `[IPv6:::1]`).
    pattern: regex(
      "^([^@\s\"]+|\"([^\"\\\\]|\\\\.)+\")@([^@\s.\[\]]+(\.[^@\s.\[\]]+)*|\[[^\[\]\s]+\])$",
    ),
    expected: "an email (e.g. \"name@example.com\")",
  ),
  (
    kind: "uuid-string",
    json-schema: "uuid",
    datetime: none,
    pattern: regex(
      "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$",
    ),
    expected: "a UUID (e.g. \"123e4567-e89b-12d3-a456-426614174000\")",
  ),
  (
    kind: "hostname-string",
    json-schema: "hostname",
    datetime: none,
    pattern: regex("^" + _label + "(\." + _label + ")*$"),
    expected: "a hostname (e.g. \"example.com\")",
  ),
  (
    kind: "ipv4-string",
    json-schema: "ipv4",
    datetime: none,
    pattern: regex("^" + _octet + "(\." + _octet + "){3}$"),
    expected: "an IPv4 address (e.g. \"192.0.2.1\")",
  ),
  (
    kind: "ipv6-string",
    json-schema: "ipv6",
    datetime: none,
    pattern: regex(_ipv6-pattern),
    expected: "an IPv6 address (e.g. \"2001:db8::1\")",
  ),
  (
    kind: "time-string",
    json-schema: "time",
    datetime: none,
    pattern: regex("^" + _clock + "$"),
    expected: "an ISO-8601 time (e.g. \"10:00:00Z\")",
  ),
)

// Kind name → row, for the engine and coerce; the keys are the list of
// format kinds.
#let _formats = _format-rows.map(row => (row.kind, row)).to-dict()

/// A string in ISO 8601 date form: `YYYY`, `YYYY-MM` or `YYYY-MM-DD`.
/// Data written in Typst may give a `datetime` with a date and no time;
/// it is checked and returned as the ISO string.
#let date-string = (kind: "date-string")
/// A string in ISO 8601 date and time form, `YYYY-MM-DDTHH:MM:SS`, with
/// an optional fraction and `Z` or `±HH:MM` offset; `T` and `Z` may be
/// lowercase and a leap second (`:60`) is allowed. Data written in Typst
/// may give a `datetime` with a date and a time; it is checked and
/// returned as the ISO string.
#let datetime-string = (kind: "datetime-string")
/// A string that looks like a URI: a scheme, `:`, then no whitespace (a
/// permissive check).
#let uri-string = (kind: "uri-string")
/// A string that looks like an email address (a permissive check).
#let email-string = (kind: "email-string")
/// A string that looks like a UUID: 8-4-4-4-12 hex digits (a permissive
/// check; the version and variant are not inspected).
#let uuid-string = (kind: "uuid-string")
/// A string that looks like a hostname: dot-separated labels of letters,
/// digits and inner hyphens (a permissive check).
#let hostname-string = (kind: "hostname-string")
/// A string in dotted-quad IPv4 form, each octet 0-255.
#let ipv4-string = (kind: "ipv4-string")
/// A string that looks like an IPv6 address, including `::` compression
/// (a permissive check; the embedded-IPv4 tail form is not accepted).
#let ipv6-string = (kind: "ipv6-string")
/// A string in `HH:MM:SS` time form, with an optional fraction and `Z`
/// or `±HH:MM` offset; `Z` may be lowercase and a leap second (`:60`) is
/// allowed.
#let time-string = (kind: "time-string")

// The string constructor lives here, beside the format table its
// `format:` reads; its length parameters are the string rows' fields
// (constraint.typ), checked by _constrain as number() checks its own.
// `format:` and `pattern:` compose as the translator composes `format`
// and `pattern`: the format kind with an extra pattern gate.

/// The first problem (error.typ) with string()'s `format`, `pattern`
/// and `expected` arguments, or none. The translator words it for the
/// JSON keywords of the same names.
#let _string-problem(format: none, pattern: none, expected: none) = {
  if format != none and _format-rows.all(row => row.json-schema != format) {
    let names = _format-rows.map(row => repr(row.json-schema))
    return _problem("format", "one of " + names.join(", "), repr(format))
  }
  if expected != none and pattern == none {
    return (
      message: "expected describes a pattern, so it needs pattern:; got expected: "
        + repr(expected)
        + " alone.",
    )
  }
  if pattern != none and type(pattern) not in (regex, str) {
    return _problem("pattern", "a regex or a string", _type-name-of(pattern))
  }
  if expected != none and type(expected) != str {
    return _problem("expected", "a string", repr(expected))
  }
}

/// A string, with an optional format, pattern and length bounds. An
/// argument left at `none` sets nothing, so `string()` is `str-type`,
/// `string(format: "email")` is `email-string` and
/// `string(pattern: p, expected: e)` is `pattern-string(p, expected: e)`.
/// Panics on a value of the wrong type, an unknown format, an
/// `expected` without a `pattern`, or length bounds no string
/// satisfies.
///
/// - min-length (int, none): The fewest characters (grapheme clusters)
///   allowed.
/// - max-length (int, none): The most characters (grapheme clusters)
///   allowed.
/// - format (str, none): A JSON Schema format name: `"date"`,
///   `"date-time"`, `"uri"`, `"email"`, `"uuid"`, `"hostname"`,
///   `"ipv4"`, `"ipv6"` or `"time"`. The string must have that form.
/// - pattern (regex, str, none): A regular expression the string must
///   match, anywhere in it unless anchored with `^…$`. With a `format`,
///   the string must have the format and match the pattern.
/// - expected (str, none): What a string matching `pattern` looks like,
///   for the error message ("expected …"). Only with `pattern`; by
///   default `"matching pattern"`.
/// -> dictionary
#let string(
  min-length: none,
  max-length: none,
  format: none,
  pattern: none,
  expected: none,
) = {
  let p = _string-problem(format: format, pattern: pattern, expected: expected)
  if p != none { _fail("string()", p) }
  let base = if format == none { str-type } else {
    (kind: _format-rows.find(row => row.json-schema == format).kind)
  }
  if pattern != none {
    let gate = if expected == none { pattern-string(pattern) } else {
      pattern-string(pattern, expected: expected)
    }
    base = if format == none { gate } else {
      (..base, pattern: gate.pattern, expected: gate.expected)
    }
  }
  _constrain("string()", base, "string", (
    min-length: min-length,
    max-length: max-length,
  ))
}

// Typst-native input for the date kinds (#134): a datetime of the
// right shape converts to the ISO string the row's regex checks, so
// validate and coerce treat it exactly like the JSON string. Wrong
// shape returns none — a time is never dropped to make a date fit.
#let _datetime-expected(row) = (
  "a string or a datetime with a date and "
    + if row.datetime { "a time" } else { "no time" }
)

#let _from-datetime(row, value) = {
  if value.year() != none and (value.hour() != none) == row.datetime {
    value.display(
      "[year]-[month]-[day]"
        + if row.datetime { "T[hour]:[minute]:[second]" } else { "" },
    )
  }
}

// The engine check for a row's kind: the datetime conversion, then the
// row's regex, then the node's own extra pattern, each a gate. A
// datetime of the wrong shape is a `format` miss that leaves no string
// to model; a regex or pattern miss still leaves the string.
#let _format-check(row) = (schema, value, ctx) => {
  let value = if type(value) == datetime and row.datetime != none {
    let converted = _from-datetime(row, value)
    if converted == none {
      let expected = _datetime-expected(row)
      return (
        errors: _error(
          ctx.path,
          "format",
          _expected-got(expected, "datetime"),
          expected: expected,
          got: value,
        ),
        value: value,
        fatal: (path: ctx.path, expected: expected, got: value),
      )
    }
    converted
  } else { value }
  if type(value) != str {
    return _type-miss(ctx.path, "string", value)
  }
  if value.match(row.pattern) == none {
    let errors = _error(
      ctx.path,
      "format",
      "expected " + row.expected + ".",
      expected: row.expected,
      got: value,
    )
    return (errors: errors, value: value, fatal: none)
  }
  // Extra pattern gate (format + pattern), on the converted string.
  (errors: _pattern-errors(schema, value, ctx.path), value: value, fatal: none)
}
