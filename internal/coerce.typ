// Assumes input has passed _validate. Unknown keys are dropped
// silently rather than panicking; top-of-branch type checks catch
// shape mismatches from direct callers who skipped validation.
//
// JSON `null` (Typst's `none`) at a value position is treated as if
// the key were absent: it returns `none` from the per-value call so
// the parent's object-pair filter or array-element filter drops it.
// Downstream renderers see "key not in dict" instead of a stray
// `none` value to special-case.
//
// Only `none` is absent. An object whose keys were all null, or an
// empty object, stays an (empty) dictionary: validate counts it as
// present, so dropping it here would hand callers a model that breaks
// the schema it just passed (a missing required key, a short array).

#import "core/error.typ": _type-name-of
#import "kinds.typ": _is-free-form
#import "kinds/format.typ": _formats, _datetime-expected, _from-datetime
// Union coercion must pick a member, and Typst has no try/catch to
// probe with — so coerce leans on the validator's verdict. Acyclic:
// validate.typ does not import coerce.
#import "validate.typ": _validate

#let _expect(expected, value) = (
  "gairm-import: coerce expected "
    + expected
    + ", got "
    + _type-name-of(value)
    + ". Run validate(data) first."
)

#let _coerce(schema, value) = {
  // Null at any value position is "key absent". The parent (object
  // or array branch below) is responsible for filtering this out.
  if value == none { return none }
  let kind = schema.kind
  if kind == "content" {
    if type(value) != str { panic(_expect("a string", value)) }
    return [#value]
  }
  let row = _formats.at(kind, default: none)
  if row != none and row.datetime != none and type(value) == datetime {
    let converted = _from-datetime(row, value)
    if converted == none { panic(_expect(_datetime-expected(row), value)) }
    return converted
  }
  // Format-specialised string kinds pass through identically to `str`
  // — the regex gate fires in _validate, not here.
  if kind == "str" or kind == "pattern-string" or kind in _formats {
    if type(value) != str { panic(_expect("a string", value)) }
    return value
  }
  if kind == "number" {
    if type(value) not in (int, float) { panic(_expect("a number", value)) }
    return value
  }
  if kind == "bool" {
    if type(value) != bool { panic(_expect("a boolean", value)) }
    return value
  }
  // Unreachable on validated input — top early return handles `none`,
  // the only legal value.
  if kind == "null" {
    panic(_expect("null", value))
  }
  // Members are polymorphic — no single type to check. Mirror the
  // validator's membership check so direct-coerce callers fail loud.
  if kind == "enum" {
    if value not in schema.values {
      panic(_expect("one of " + schema.values.map(repr).join(", "), value))
    }
    return value
  }
  if kind == "array" {
    if type(value) != array { panic(_expect("an array", value)) }
    // Drop null elements: a null in an array of strings would
    // otherwise surface as a stray `none` to downstream renderers.
    return value.map(elem => _coerce(schema.elem, elem)).filter(e => e != none)
  }
  if kind == "object" {
    if type(value) != dictionary { panic(_expect("an object", value)) }
    // Opaque, like an `additional: true` extra: no null cleanup, so
    // `custom: (a: none)` survives as given.
    if _is-free-form(schema) { return value }
    let additional = schema.at("additional", default: none)
    return value
      .pairs()
      .filter(((key, _)) => key in schema.shape or additional != none)
      .map(((key, sub-value)) => {
        let sub = if key in schema.shape {
          _coerce(schema.shape.at(key), sub-value)
        } else if additional == true {
          // `additionalProperties: true` — pass through; validate.typ
          // mirrors this by returning `()` (no validation).
          sub-value
        } else {
          _coerce(additional, sub-value)
        }
        (key, sub)
      })
      .filter(((_, coerced)) => coerced != none)
      .to-dict()
  }
  // Union: delegate to the first member the value validates against.
  // For one-of, validation already guaranteed exactly one; direct
  // callers who skipped validation fail like every other branch.
  if kind == "union" {
    let matching = schema.members.find(m => _validate(m, value, ()).len() == 0)
    if matching == none {
      panic(_expect("a value matching one of the union alternatives", value))
    }
    return _coerce(matching, value)
  }
  // `not` constrains what a value may NOT be — there is no shape to
  // coerce toward, so pass through verbatim (same contract as
  // `additional: true` extras).
  if kind == "not" { return value }
  panic("gairm-import: internal — unknown schema kind " + repr(kind))
}
