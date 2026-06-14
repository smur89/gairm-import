// Pure coercer. Assumes input has passed _validate against the same
// schema. Wraps content-type strings into Typst content blocks so
// renderers consume them positionally; everything else passes through
// unchanged. Unknown keys in objects are silently skipped — under the
// normal pipeline the validator has already rejected them, and when
// coerce-resume is called directly we'd rather drop strays than emit
// a cryptic Typst dictionary-access panic.
//
// Top-of-branch type checks raise a json-resume-prefixed error when
// the value type doesn't match the schema kind, so direct callers who
// skipped validate-resume get a friendly diagnostic on shape
// mismatches (e.g. a string where an object was expected) instead of
// a Typst method-resolution panic from .pairs() / .map().

#let _coerce(schema, value) = {
  let kind = schema.kind
  if kind == "content" { return [#value] }
  if kind in ("str", "number") { return value }
  if kind == "array" {
    if type(value) != array {
      panic(
        "json-resume: coerce-resume expected an array, got " +
          repr(type(value)) + ". Run validate-resume first.",
      )
    }
    return value.map(elem => _coerce(schema.elem, elem))
  }
  if kind == "object" {
    if type(value) != dictionary {
      panic(
        "json-resume: coerce-resume expected an object, got " +
          repr(type(value)) + ". Run validate-resume first.",
      )
    }
    return value.pairs()
      .filter(((key, _)) => key in schema.shape)
      .map(((key, sub-value)) => (key, _coerce(schema.shape.at(key), sub-value)))
      .to-dict()
  }
  panic("json-resume: internal — unknown schema kind " + repr(kind))
}
