// pattern-string: per-instance regex gate with caller-supplied
// `expected` hint. Coverage:
//
//  - positive case — value matches the regex
//  - negative case — value fails the regex, error carries expected hint
//  - unanchored pattern still applies as authored (no auto-anchoring)
//  - wrong type still yields a type-error, not a pattern-error
//  - default `expected` hint when caller omits it
//  - nested under array-of / object: paths stay correct

#import "../internal/validate.typ": _validate
#import "../internal/kinds.typ": pattern-string, object, array-of

// ---- positive --------------------------------------------------------

#let country-code = pattern-string(
  "^[A-Z]{2}$",
  expected: "an ISO 3166-1 alpha-2 code",
)
#assert.eq(_validate(country-code, "US", ("c",)), ())
#assert.eq(_validate(country-code, "IE", ("c",)), ())

// ---- negative — error carries the caller-supplied hint --------------

#let pat-fail(schema, value, path) = {
  let errs = _validate(schema, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

#let m1 = pat-fail(country-code, "USA", ("basics", "countryCode"))
#assert(m1.contains("ISO 3166-1 alpha-2 code"))

#assert(
  pat-fail(country-code, "us", ("c",)).contains("ISO 3166-1 alpha-2 code"),
)
#assert(pat-fail(country-code, "", ("c",)).contains("ISO 3166-1 alpha-2 code"))
#assert(
  pat-fail(country-code, "U1", ("c",)).contains("ISO 3166-1 alpha-2 code"),
)

// ---- unanchored pattern applies as authored -------------------------
//
// Typst's `match` is substring-based; anchoring is the schema author's
// job. Without `^…$` a pattern accepts any string containing a match.

#let contains-digit = pattern-string(
  "[0-9]",
  expected: "a string containing a digit",
)
#assert.eq(_validate(contains-digit, "abc123", ("x",)), ())
#assert.eq(_validate(contains-digit, "1", ("x",)), ())
#assert.eq(_validate(contains-digit, "v2-final", ("x",)), ())
#assert(pat-fail(contains-digit, "no-digits-here", ("x",)).contains("digit"))

// ---- wrong type yields a type-error, not a pattern-error ------------

#let type-err = _validate(country-code, 42, ("c",))
#assert.eq(type-err.len(), 1)
#assert(type-err.at(0).message.contains("expected string"))
#assert(type-err.at(0).message.contains("got integer"))

// ---- default `expected` hint ----------------------------------------

#let bare = pattern-string("^x$")
#assert.eq(_validate(bare, "x", ("b",)), ())
#assert(pat-fail(bare, "y", ("b",)).contains("matching pattern"))

// ---- Nested under array-of / object: paths stay correct -------------

#let schema = object((
  codes: array-of(country-code),
  primary: country-code,
))

#let nested-errs = _validate(
  schema,
  (
    codes: ("US", "usa", "IE"),
    primary: "x",
  ),
  (),
)
#assert.eq(nested-errs.len(), 2)
#let paths = nested-errs.map(e => e.path)
#assert(("codes", 1) in paths)
#assert(("primary",) in paths)
