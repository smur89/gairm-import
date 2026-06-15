// Strict loader for canonical JSON Resume data
// (https://jsonresume.org/schema). The engines under internal/ are
// pure functions of (schema, value); see
// tests/engine_schema_agnostic.typ for the BYO-schema contract.

#import "internal/schema.typ": resume-schema, str-type, content-type, number-type, array-of, object
#import "internal/validate.typ": _validate
#import "internal/coerce.typ": _coerce
#import "internal/errors.typ": _format-report
#import "internal/json-schema.typ": schema-from-json-schema

// Format a list of `(path, message)` records into the same combined
// report `parse-resume` produces — for BYO consumers calling
// `validate(schema, data)` themselves.
#let format-errors(errors) = _format-report(errors)

// Generic engines bound to a caller-supplied schema. Returns a list
// of {path, message} records; empty = valid.
#let validate(schema, data) = _validate(schema, data, ())

// Assumes data has passed `validate(schema, ...)`. Unknown keys are
// dropped silently rather than panicking on direct callers.
#let coerce(schema, data) = _coerce(schema, data)

// Strict canonical wrappers — pre-bound to resume-schema. The engines
// treat `none` at any value position as "key absent", which is the
// right rule for leaves inside a document but would silently accept a
// null root. These wrappers reject that explicitly so a caller passing
// the wrong thing gets a friendly panic, not garbage. (`parse-resume`
// rejects `none` via its own dict-or-string type check below.)

#let validate-resume(data) = {
  if data == none { panic("json-resume: input must be a dict, got null.") }
  _validate(resume-schema, data, ())
}

#let coerce-resume(data) = {
  if data == none { panic("json-resume: input must be a dict, got null.") }
  _coerce(resume-schema, data)
}

// String paths must start with "/" because Typst resolves relative
// paths against the file containing the call — for this package
// that's the @preview cache, which is not what callers want.
#let parse-resume(data) = {
  let dict-data = if type(data) == str {
    if not data.starts-with("/") {
      panic(
        "json-resume: parse-resume with a string path requires the path " +
          "to start with \"/\" (resolved from the typst root). Got: " + repr(data) + ". " +
          "To use a path relative to your own .typ file, call json() " +
          "directly: parse-resume(json(" + repr(data) + ")).",
      )
    }
    json(data)
  } else if type(data) == dictionary {
    data
  } else {
    panic(
      "json-resume: parse-resume expected a dict or a string path, got " +
        repr(type(data)) + ".",
    )
  }
  let errors = validate-resume(dict-data)
  // assert preserves newlines in the diagnostic; panic repr-escapes
  // them and collapses the bullet list onto one line.
  assert(errors.len() == 0, message: format-errors(errors))
  coerce-resume(dict-data)
}
