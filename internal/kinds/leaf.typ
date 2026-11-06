// The leaf kinds' constants and constructors: the scalars, the
// per-node regex gate and enums. The format constants live in
// format.typ, the containers and combinators in structure.typ, and
// registry.typ holds a descriptor for every kind.

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

// "Must be null or absent": `none` passes via the engine's global
// early return, non-none hits the kind branch and errors.
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
