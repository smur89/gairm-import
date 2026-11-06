// The leaf kinds' constants and constructors: the scalars, the
// per-node regex gate and enums, and the checks the engine runs for
// them. The format constants live in format.typ, the containers and
// combinators in structure.typ, and registry.typ holds a descriptor
// for every kind.

#import "../core/error.typ": _error, _type-miss, _type-name-of
#import "constraint.typ": _constraint-errors

/// A string, passed through as it is.
#let str-type = (kind: "str")
/// A string that the model returns as Typst `content`, so it splices into
/// markup.
#let content-type = (kind: "content")
/// An integer or a float.
#let number-type = (kind: "number")
/// A boolean.
#let bool-type = (kind: "bool")

// JSON Schema `integer`: any number with a zero fractional part
// (draft-7 semantics — 1.0 passes, 1.5 fails). Same "number" kind with
// a validation flag rather than a new kind, so coerce / introspect /
// lens need no extra branch.
/// A number with no fractional part. `1.0` passes and `1.5` fails.
#let integer-type = (kind: "number", integer: true)

// "Must be null or absent". By default a null is absent before any
// kind sees it; in strict-null mode it reaches the check, which takes
// it.
/// `null` or an absent key. Any other value is an error.
#let null-type = (kind: "null")

// Per-instance regex gate — a constructor, not a constant, because
// each schema node carries its own regex and hint.
/// A string that must match a regular expression. The match may be
/// anywhere in the string, so anchor the pattern with `^…$` for a
/// full match.
///
/// - re (regex, str): The pattern.
/// - expected (str): What the value should be, for the error message
///   ("expected …").
/// -> dictionary
#let pattern-string(re, expected: "matching pattern") = (
  kind: "pattern-string",
  pattern: if type(re) == regex { re } else { regex(re) },
  expected: expected,
)

// Mixed-type members allowed — the validator's `in` check gates on
// equality, not type. `const` is a singleton enum.
/// One of a fixed list of values. The values may be of mixed types.
///
/// - values (array): The allowed values.
/// -> dictionary
#let enum-of(values) = (kind: "enum", values: values)
/// Exactly one value. Same as `enum-of` with a single value.
///
/// - value (any): The only allowed value.
/// -> dictionary
#let const-of(value) = enum-of((value,))

// ---- engine behaviour ------------------------------------------------
//
// A leaf check is (schema, value, ctx) -> (errors, value, fatal). It
// judges the JSON-level value and may normalise it (a datetime becomes
// its ISO string), but never wraps it: the descriptor's `model` does
// that. When the check passes, the engine adds the family's constraint
// errors.
//
// `fatal` is none, or (expected, got) when the value leaves no model at
// all; coerce panics with it ("coerce expected <expected>, got …").
// Each check says so itself: a miss that still leaves a usable value (a
// pattern, a format regex, `integer`) has no fatal.
//
// A check emits `type` exactly when the value's JSON type is wrong for
// the kind: a union counts a member as claiming a value unless the
// member reports `type` at the union's own path.

#let _pass(value) = (errors: (), value: value, fatal: none)

/// A check that only gates on the value's Typst type.
#let _typed-check(types, expected, noun) = (schema, value, ctx) => {
  if type(value) in types { _pass(value) } else {
    _type-miss(ctx.path, expected, noun, value)
  }
}

#let _string-check = _typed-check((str,), "string", "a string")
#let _bool-check = _typed-check((bool,), "boolean", "a boolean")

// `integer: true` (integer-type / JSON Schema `integer`): draft-7
// semantics, so a float with zero fractional part passes. The miss is
// `integer`, not `type`: the member still takes numbers, so a union
// counts it as claiming the value. Nor is it a gate: the number rows
// still judge the value alongside it.
#let _number-check(schema, value, ctx) = {
  if type(value) not in (int, float) {
    return _type-miss(ctx.path, "number", "a number", value)
  }
  if schema.at("integer", default: false) and calc.fract(value) != 0 {
    let errors = _error(
      ctx.path,
      "integer",
      "expected an integer, got " + str(value) + ".",
      got: value,
    )
    let constraint-errors = _constraint-errors(
      schema,
      "number",
      value,
      ctx.path,
    )
    return (errors: errors + constraint-errors, value: value, fatal: none)
  }
  _pass(value)
}

// An absent value never reaches a check, so a null arrives here only
// in strict-null mode, where it is this kind's one value. Every other
// check rejects a null with `type` ("got null") at its type gate.
#let _null-check(schema, value, ctx) = if value == none { _pass(value) } else {
  _type-miss(ctx.path, "null", "null", value)
}

// The node's own `pattern` gate, if it carries one (a pattern-string,
// or a format kind with an extra pattern).
#let _pattern-errors(schema, value, path) = {
  if "pattern" in schema and value.match(schema.pattern) == none {
    // Hand-built nodes may omit `expected`; default as pattern-string
    // does.
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

// pattern + hint travel on the schema node rather than via the format
// table, since each instance is unique.
#let _pattern-check(schema, value, ctx) = {
  if type(value) != str {
    return _type-miss(ctx.path, "string", "a string", value)
  }
  (errors: _pattern-errors(schema, value, ctx.path), value: value, fatal: none)
}

// A JSON type name per value, with int and float as the one number
// type JSON has.
#let _json-type-name(value) = {
  if type(value) in (int, float) { "number" } else { _type-name-of(value) }
}

#let _enum-check(schema, value, ctx) = {
  if value in schema.values { return _pass(value) }
  let listed = schema.values.map(repr).join(", ")
  let message = "expected one of " + listed + ", got " + repr(value) + "."
  // `type` when no value shares the value's JSON type, so a union
  // doesn't count this member as claiming it; `enum` otherwise.
  let names = schema.values.map(_json-type-name).dedup()
  let errors = if _json-type-name(value) not in names {
    _error(
      ctx.path,
      "type",
      message,
      expected: names.join(" or "),
      got: _type-name-of(value),
    )
  } else {
    _error(ctx.path, "enum", message, expected: schema.values, got: value)
  }
  // Either way no listed value is left to model, and coerce names them.
  (
    errors: errors,
    value: value,
    fatal: (expected: "one of " + listed, got: value),
  )
}
