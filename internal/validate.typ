// Subtrees under unknown keys are not walked — their expected shape
// is undefined.
//
// JSON `null` (Typst's `none`) at a value position is treated as if
// the key were absent: no type error, no recursion. Per-key null
// values in objects, null array elements, and entire-section nulls
// are all absorbed by the top-of-function early return — recursion
// handles them uniformly. The required-keys check below is the only
// place that still needs an explicit null check (a present-but-null
// required key must still count as missing). See README "Errors"
// section for the user-facing rationale.

#import "errors.typ": _type-name-of, _closest-match
#import "kinds.typ": (
  _format-string-kinds, _datetime-kinds, _datetime-expected, _from-datetime,
)

#let _err(path, msg) = ((path: path, message: msg),)

#let _type-error(path, expected, value) = _err(
  path,
  "expected " + expected + ", got " + _type-name-of(value) + ".",
)

// The node's own `pattern` gate, if it carries one (a pattern-string, or
// a format kind with an extra pattern).
#let _pattern-errs(schema, value, path) = {
  if "pattern" in schema and value.match(schema.pattern) == none {
    // Hand-built nodes may omit `expected`; default as pattern-string does.
    let expected = schema.at("expected", default: "matching pattern")
    _err(path, "expected " + expected + ".")
  } else { () }
}

// Clusters, not bytes — JSON Schema talks "length" without pinning.
#let _string-length-errs(schema, value, path) = {
  let min = schema.at("min-length", default: none)
  let max = schema.at("max-length", default: none)
  if min == none and max == none { return () }
  let n = value.clusters().len()
  let errs = ()
  if min != none and n < min {
    errs += _err(
      path,
      "expected string length ≥ " + str(min) + ", got " + str(n) + ".",
    )
  }
  if max != none and n > max {
    errs += _err(
      path,
      "expected string length ≤ " + str(max) + ", got " + str(n) + ".",
    )
  }
  errs
}

#let _number-range-errs(schema, value, path) = {
  let errs = ()
  let mn = schema.at("minimum", default: none)
  if mn != none and value < mn {
    errs += _err(path, "expected ≥ " + str(mn) + ", got " + str(value) + ".")
  }
  let mx = schema.at("maximum", default: none)
  if mx != none and value > mx {
    errs += _err(path, "expected ≤ " + str(mx) + ", got " + str(value) + ".")
  }
  let emn = schema.at("exclusive-minimum", default: none)
  if emn != none and value <= emn {
    errs += _err(path, "expected > " + str(emn) + ", got " + str(value) + ".")
  }
  let emx = schema.at("exclusive-maximum", default: none)
  if emx != none and value >= emx {
    errs += _err(path, "expected < " + str(emx) + ", got " + str(value) + ".")
  }
  let mult = schema.at("multiple-of", default: none)
  // A schema bug, not a data error: the translator rejects it, but a
  // hand-built node can carry it.
  if mult != none and mult <= 0 {
    panic(
      "gairm-import: multiple-of must be positive, got " + str(mult) + ".",
    )
  }
  // Integers stay exact; floats compare the ratio with a tolerance, since
  // calc.rem(0.3, 0.1) is not 0.
  let off = if mult == none { false } else if (
    type(value) == int and type(mult) == int
  ) {
    calc.rem(value, mult) != 0
  } else {
    let q = value / mult
    calc.abs(q - calc.round(q)) >= 1e-9
  }
  if off {
    errs += _err(
      path,
      "expected multiple of " + str(mult) + ", got " + str(value) + ".",
    )
  }
  errs
}

// A value as coerce's null-as-absent rule leaves it: null keys and
// null elements removed at every depth. Uniqueness compares these, or
// items differing only by a null key would pass and then coerce to
// duplicates.
#let _strip-nulls(value) = {
  if type(value) == dictionary {
    value
      .pairs()
      .filter(((_, v)) => v != none)
      .map(((k, v)) => (k, _strip-nulls(v)))
      .to-dict()
  } else if type(value) == array {
    value.filter(v => v != none).map(_strip-nulls)
  } else { value }
}

// Filter `none` first — coerce drops them, so raw counts would
// validate inputs whose rendered model violates min-items. Duplicate
// reports cite original positions so callers can find them.
#let _array-constraint-errs(schema, value, path) = {
  let errs = ()
  let present = value.enumerate().filter(((_, elem)) => elem != none)
  let n = present.len()
  let min = schema.at("min-items", default: none)
  if min != none and n < min {
    errs += _err(
      path,
      "expected array length ≥ " + str(min) + ", got " + str(n) + ".",
    )
  }
  let max = schema.at("max-items", default: none)
  if max != none and n > max {
    errs += _err(
      path,
      "expected array length ≤ " + str(max) + ", got " + str(n) + ".",
    )
  }
  if schema.at("unique-items", default: false) {
    let stripped = present.map(((_, elem)) => _strip-nulls(elem))
    for i in range(n) {
      for j in range(i + 1, n) {
        let orig-i = present.at(i).at(0)
        let orig-j = present.at(j).at(0)
        if stripped.at(i) == stripped.at(j) {
          errs += _err(
            path,
            "expected unique items, duplicate at indices "
              + str(orig-i)
              + " and "
              + str(orig-j)
              + ".",
          )
          return errs
        }
      }
    }
  }
  errs
}

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

// Tightened over the upstream JSON Resume regexes, which accept
// impossible months / days because they use [0-1][0-9] / [0-3][0-9].
// Deliberately permissive (no full RFC compliance). Message omits the
// offending value — the path already names the field, the canonical
// example in `expected` is the actionable hint.
#let _format-specs = (
  "date-string": (
    pattern: regex(
      "^([0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])|[0-9]{4}-(0[1-9]|1[0-2])|[0-9]{4})$",
    ),
    expected: "an ISO-8601 date (e.g. \"2024-01-15\")",
  ),
  "datetime-string": (
    pattern: regex(
      "^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|[+-]([01][0-9]|2[0-3]):[0-5][0-9])?$",
    ),
    expected: "an ISO-8601 datetime (e.g. \"2024-01-15T10:00:00Z\")",
  ),
  "uri-string": (
    pattern: regex("^[A-Za-z][A-Za-z0-9+.\-]*://\S+$"),
    expected: "a URI (e.g. \"https://example.com\")",
  ),
  "email-string": (
    pattern: regex("^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$"),
    expected: "an email (e.g. \"name@example.com\")",
  ),
  "uuid-string": (
    pattern: regex(
      "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$",
    ),
    expected: "a UUID (e.g. \"123e4567-e89b-12d3-a456-426614174000\")",
  ),
  "hostname-string": (
    pattern: regex("^" + _label + "(\." + _label + ")*$"),
    expected: "a hostname (e.g. \"example.com\")",
  ),
  "ipv4-string": (
    pattern: regex("^" + _octet + "(\." + _octet + "){3}$"),
    expected: "an IPv4 address (e.g. \"192.0.2.1\")",
  ),
  "ipv6-string": (
    pattern: regex(_ipv6-pattern),
    expected: "an IPv6 address (e.g. \"2001:db8::1\")",
  ),
  "time-string": (
    pattern: regex(
      "^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|[+-]([01][0-9]|2[0-3]):[0-5][0-9])?$",
    ),
    expected: "an ISO-8601 time (e.g. \"10:00:00Z\")",
  ),
)

// Load-time drift guard: a format kind added to kinds.typ but not here
// (or vice versa) fails at import, not at validate time on unlucky input.
#assert(
  _format-specs.keys().sorted() == _format-string-kinds.sorted(),
  message: "gairm-import: internal — _format-specs is out of sync with kinds._format-string-kinds.",
)

// Whether a union member takes values of this one's type at all, read
// from the schema rather than from its error text, which enum, range
// and pattern errors would otherwise mimic.
#let _accepts-type(schema, value) = {
  let kind = schema.kind
  let t = type(value)
  if kind in ("str", "content", "pattern-string") { return t == str }
  if kind in _format-specs {
    return t == str or (t == datetime and kind in _datetime-kinds)
  }
  if kind == "number" { return t in (int, float) }
  if kind == "bool" { return t == bool }
  if kind == "array" { return t == array }
  if kind == "object" { return t == dictionary }
  // int and float are one JSON number type.
  if kind == "enum" {
    let numeric = (int, float)
    return schema.values.any(v => (
      type(v) == t or (type(v) in numeric and t in numeric)
    ))
  }
  if kind == "union" {
    return schema.members.any(m => _accepts-type(m, value))
  }
  // `not` admits every type its member rejects, so it can't be ruled out.
  if kind == "not" { return true }
  // `null` takes only `none`, which never reaches a union branch.
  false
}

#let _validate(schema, value, path) = {
  // Null at any value position is "key absent" — no error, no
  // recursion. Single early return handles every shape uniformly:
  // standalone scalars, array elements (via the per-element call),
  // and per-key sub-values inside objects (via the per-key call).
  if value == none { return () }
  let kind = schema.kind
  if kind in ("str", "content") {
    if type(value) != str { return _type-error(path, "string", value) }
    return _string-length-errs(schema, value, path)
  }
  if kind == "enum" {
    if value in schema.values { return () }
    return _err(
      path,
      "expected one of "
        + schema.values.map(repr).join(", ")
        + ", got "
        + repr(value)
        + ".",
    )
  }
  if kind in _format-specs {
    let value = if type(value) == datetime and kind in _datetime-kinds {
      let converted = _from-datetime(kind, value)
      if converted == none {
        return _err(
          path,
          "expected " + _datetime-expected(kind) + ", got datetime.",
        )
      }
      converted
    } else { value }
    if type(value) != str { return _type-error(path, "string", value) }
    let spec = _format-specs.at(kind)
    if value.match(spec.pattern) == none {
      return _err(path, "expected " + spec.expected + ".")
    }
    // Extra pattern gate (format + pattern), on the converted string.
    let errs = _pattern-errs(schema, value, path)
    if errs != () { return errs }
    return _string-length-errs(schema, value, path)
  }
  // pattern + hint travel on the schema node rather than via the
  // _format-specs table above, since each instance is unique.
  if kind == "pattern-string" {
    if type(value) != str { return _type-error(path, "string", value) }
    let errs = _pattern-errs(schema, value, path)
    if errs != () { return errs }
    return _string-length-errs(schema, value, path)
  }
  if kind == "number" {
    if type(value) not in (int, float) {
      return _type-error(path, "number", value)
    }
    // `integer: true` (kinds.typ's integer-type / JSON Schema `integer`):
    // draft-7 semantics, so a float with zero fractional part passes.
    let errs = if (
      schema.at("integer", default: false) and calc.fract(value) != 0
    ) {
      _err(path, "expected an integer, got " + str(value) + ".")
    } else { () }
    return errs + _number-range-errs(schema, value, path)
  }
  if kind == "bool" {
    if type(value) != bool { return _type-error(path, "boolean", value) }
    return ()
  }
  // `none` succeeds via the top early return; non-none can only fail.
  if kind == "null" { return _type-error(path, "null", value) }
  if kind == "array" {
    if type(value) != array { return _type-error(path, "array", value) }
    let elem-errs = value
      .enumerate()
      .map(((i, elem)) => _validate(schema.elem, elem, path + (i,)))
      .flatten()
    return elem-errs + _array-constraint-errs(schema, value, path)
  }
  if kind == "object" {
    if type(value) != dictionary { return _type-error(path, "object", value) }
    let additional = schema.at("additional", default: none)
    let per-key-errs = value
      .pairs()
      .map(((key, sub-value)) => {
        if key in schema.shape {
          _validate(schema.shape.at(key), sub-value, path + (key,))
        } else if additional == true {
          // `additionalProperties: true` — no validation. coerce.typ
          // mirrors this by passing the value through verbatim.
          ()
        } else if additional != none {
          _validate(additional, sub-value, path + (key,))
        } else {
          // Strict branch: fuzzy suggestion if the typo is within edit
          // distance 2 of a valid key, otherwise the full key list.
          // Unknown key with null value still flagged — silently
          // swallowing typos defeats the point of strict validation.
          let suggestion = _closest-match(key, schema.shape.keys(), 2)
          let tail = if suggestion != none {
            "Did you mean " + repr(suggestion) + "?"
          } else {
            "Valid keys: " + schema.shape.keys().join(", ") + "."
          }
          _err(path + (key,), "unknown key " + repr(key) + ". " + tail)
        }
      })
      .flatten()
    // A required key whose value is explicit null counts as missing —
    // null-as-absent applies uniformly.
    let required = schema.at("required-keys", default: ())
    let missing-errs = required
      .filter(k => k not in value or value.at(k) == none)
      .map(k => _err(path + (k,), "missing required key " + repr(k) + "."))
      .flatten()
    // Null-as-absent again: a none trigger does not fire, and a none
    // dependent is missing.
    let dependent-errs = schema
      .at("dependent-required", default: (:))
      .pairs()
      .filter(((trigger, _)) => value.at(trigger, default: none) != none)
      .map(((trigger, dependents)) => dependents
        .filter(d => value.at(d, default: none) == none)
        .map(d => _err(
          path,
          repr(d) + " is required when " + repr(trigger) + " is present.",
        )))
      .flatten()
    return per-key-errs + missing-errs + dependent-errs
  }
  // anyOf / oneOf. One summary error at the union's own path rather
  // than every member's failure list — member errors describe branches
  // the value never claimed to match, so replaying them all is noise.
  if kind == "union" {
    // Each member validated once: re-validating per check made nested
    // unions exponential in depth.
    let results = schema.members.map(m => _validate(m, value, path))
    let matches = results.filter(errs => errs.len() == 0).len()
    if matches == 1 or (matches > 1 and not schema.exclusive) { return () }
    if matches > 1 {
      return _err(
        path,
        "expected exactly one alternative to match, but "
          + str(matches)
          + " matched.",
      )
    }
    // When exactly one member accepts the value's type, its own errors
    // say what is wrong; the generic summary would read like a type
    // error for a right-typed value that merely broke a constraint.
    let claimed = schema
      .members
      .zip(results)
      .filter(((m, _)) => _accepts-type(m, value))
    if claimed.len() == 1 { return claimed.at(0).at(1) }
    let alternatives = schema.members.map(m => m.kind).join(" | ")
    let quantifier = if schema.exclusive { "exactly one" } else { "one" }
    return _err(
      path,
      "expected a value matching "
        + quantifier
        + " of: "
        + alternatives
        + "; none matched.",
    )
  }
  // `not` inverts the member verdict; the member's own errors are
  // discarded (they describe why the value is ACCEPTABLE here).
  if kind == "not" {
    if _validate(schema.member, value, path).len() == 0 {
      return _err(
        path,
        "expected a value not matching the negated "
          + schema.member.kind
          + " schema.",
      )
    }
    return ()
  }
  panic("gairm-import: internal — unknown schema kind " + repr(kind))
}
