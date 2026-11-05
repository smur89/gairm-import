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

#import "core/error.typ": _error, _type-name-of, _closest-match
#import "kinds/format.typ": _formats, _datetime-expected, _from-datetime

#let _type-error(path, expected, value) = {
  let got = _type-name-of(value)
  _error(
    path,
    "type",
    "expected " + expected + ", got " + got + ".",
    expected: expected,
    got: got,
  )
}

// The node's own `pattern` gate, if it carries one (a pattern-string, or
// a format kind with an extra pattern).
#let _pattern-errs(schema, value, path) = {
  if "pattern" in schema and value.match(schema.pattern) == none {
    // Hand-built nodes may omit `expected`; default as pattern-string does.
    let expected = schema.at("expected", default: "matching pattern")
    _error(
      path,
      "pattern",
      "expected " + expected + ".",
      expected: expected,
      got: value,
    )
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
    errs += _error(
      path,
      "length",
      "expected string length ≥ " + str(min) + ", got " + str(n) + ".",
      expected: (min-length: min),
      got: n,
    )
  }
  if max != none and n > max {
    errs += _error(
      path,
      "length",
      "expected string length ≤ " + str(max) + ", got " + str(n) + ".",
      expected: (max-length: max),
      got: n,
    )
  }
  errs
}

#let _number-range-errs(schema, value, path) = {
  let errs = ()
  let mn = schema.at("minimum", default: none)
  if mn != none and value < mn {
    errs += _error(
      path,
      "range",
      "expected ≥ " + str(mn) + ", got " + str(value) + ".",
      expected: (minimum: mn),
      got: value,
    )
  }
  let mx = schema.at("maximum", default: none)
  if mx != none and value > mx {
    errs += _error(
      path,
      "range",
      "expected ≤ " + str(mx) + ", got " + str(value) + ".",
      expected: (maximum: mx),
      got: value,
    )
  }
  let emn = schema.at("exclusive-minimum", default: none)
  if emn != none and value <= emn {
    errs += _error(
      path,
      "range",
      "expected > " + str(emn) + ", got " + str(value) + ".",
      expected: (exclusive-minimum: emn),
      got: value,
    )
  }
  let emx = schema.at("exclusive-maximum", default: none)
  if emx != none and value >= emx {
    errs += _error(
      path,
      "range",
      "expected < " + str(emx) + ", got " + str(value) + ".",
      expected: (exclusive-maximum: emx),
      got: value,
    )
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
    errs += _error(
      path,
      "multiple",
      "expected multiple of " + str(mult) + ", got " + str(value) + ".",
      expected: (multiple-of: mult),
      got: value,
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
    errs += _error(
      path,
      "items",
      "expected array length ≥ " + str(min) + ", got " + str(n) + ".",
      expected: (min-items: min),
      got: n,
    )
  }
  let max = schema.at("max-items", default: none)
  if max != none and n > max {
    errs += _error(
      path,
      "items",
      "expected array length ≤ " + str(max) + ", got " + str(n) + ".",
      expected: (max-items: max),
      got: n,
    )
  }
  if schema.at("unique-items", default: false) {
    let stripped = present.map(((_, elem)) => _strip-nulls(elem))
    for i in range(n) {
      for j in range(i + 1, n) {
        let orig-i = present.at(i).at(0)
        let orig-j = present.at(j).at(0)
        if stripped.at(i) == stripped.at(j) {
          errs += _error(
            path,
            "unique",
            "expected unique items, duplicate at indices "
              + str(orig-i)
              + " and "
              + str(orig-j)
              + ".",
            got: (orig-i, orig-j),
          )
          return errs
        }
      }
    }
  }
  errs
}

// A JSON type name per value, with int and float as the one number
// type JSON has.
#let _json-type-name(value) = {
  if type(value) in (int, float) { "number" } else { _type-name-of(value) }
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
    let message = (
      "expected one of "
        + schema.values.map(repr).join(", ")
        + ", got "
        + repr(value)
        + "."
    )
    // `type` when no value shares the value's JSON type, so a union
    // doesn't count this member as claiming it; `enum` otherwise.
    let names = schema.values.map(_json-type-name).dedup()
    if _json-type-name(value) not in names {
      return _error(
        path,
        "type",
        message,
        expected: names.join(" or "),
        got: _type-name-of(value),
      )
    }
    return _error(path, "enum", message, expected: schema.values, got: value)
  }
  if kind in _formats {
    let row = _formats.at(kind)
    let value = if type(value) == datetime and row.datetime != none {
      let converted = _from-datetime(row, value)
      if converted == none {
        return _error(
          path,
          "format",
          "expected " + _datetime-expected(row) + ", got datetime.",
          expected: _datetime-expected(row),
          got: value,
        )
      }
      converted
    } else { value }
    if type(value) != str { return _type-error(path, "string", value) }
    if value.match(row.pattern) == none {
      return _error(
        path,
        "format",
        "expected " + row.expected + ".",
        expected: row.expected,
        got: value,
      )
    }
    // Extra pattern gate (format + pattern), on the converted string.
    let errs = _pattern-errs(schema, value, path)
    if errs != () { return errs }
    return _string-length-errs(schema, value, path)
  }
  // pattern + hint travel on the schema node rather than via the
  // format table, since each instance is unique.
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
      // `integer`, not `type`: the member still takes numbers, so a
      // union counts it as claiming the value.
      _error(
        path,
        "integer",
        "expected an integer, got " + str(value) + ".",
        got: value,
      )
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
          _error(
            path + (key,),
            "unknown-key",
            "unknown key " + repr(key) + ". " + tail,
            expected: schema.shape.keys(),
            got: key,
          )
        }
      })
      .flatten()
    // A required key whose value is explicit null counts as missing —
    // null-as-absent applies uniformly.
    let required = schema.at("required-keys", default: ())
    let missing-errs = required
      .filter(k => k not in value or value.at(k) == none)
      .map(k => _error(
        path + (k,),
        "required",
        "missing required key " + repr(k) + ".",
      ))
      .flatten()
    // Null-as-absent again: a none trigger does not fire, and a none
    // dependent is missing.
    let dependent-errs = schema
      .at("dependent-required", default: (:))
      .pairs()
      .filter(((trigger, _)) => value.at(trigger, default: none) != none)
      .map(((trigger, dependents)) => dependents
        .filter(d => value.at(d, default: none) == none)
        .map(d => _error(
          path,
          "dependent",
          repr(d) + " is required when " + repr(trigger) + " is present.",
          expected: d,
          got: trigger,
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
    let kinds = schema.members.map(m => m.kind)
    if matches > 1 {
      return _error(
        path,
        "union",
        "expected exactly one alternative to match, but "
          + str(matches)
          + " matched.",
        expected: kinds,
      )
    }
    // A member claims the value when it has no `type` error at the
    // union's own path. When exactly one claims, its own errors say what
    // is wrong; the generic summary would read like a type error for a
    // right-typed value that merely broke a constraint.
    let claimed = results.filter(errs => {
      not errs.any(e => (
        e.code == "type" and e.path == path
      ))
    })
    if claimed.len() == 1 { return claimed.first() }
    let alternatives = kinds.join(" | ")
    let quantifier = if schema.exclusive { "exactly one" } else { "one" }
    let message = (
      "expected a value matching "
        + quantifier
        + " of: "
        + alternatives
        + "; none matched."
    )
    // No member takes the value's type at all: a type error, so an
    // enclosing union doesn't count this one as claiming it either.
    if claimed.len() == 0 {
      return _error(
        path,
        "type",
        message,
        expected: alternatives,
        got: _type-name-of(value),
      )
    }
    return _error(path, "union", message, expected: kinds)
  }
  // `not` inverts the member verdict; the member's own errors are
  // discarded (they describe why the value is ACCEPTABLE here).
  if kind == "not" {
    if _validate(schema.member, value, path).len() == 0 {
      return _error(
        path,
        "not",
        "expected a value not matching the negated "
          + schema.member.kind
          + " schema.",
      )
    }
    return ()
  }
  panic("gairm-import: internal — unknown schema kind " + repr(kind))
}
