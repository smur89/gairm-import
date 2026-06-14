// json-resume — load and validate canonical JSON Resume data for any
// Typst CV template. Strict to the published schema at
// https://jsonresume.org/schema. Renderer-specific extensions (labels,
// theme preferences, header decorations, …) are out of scope — they
// belong in the consuming template, layered on top of the normalised
// dict returned here.
//
// The validate / coerce engines under internal/ are pure (schema,
// value) functions; only the public symbols below pre-bind the
// canonical resume-schema. See tests/engine_schema_agnostic.typ for
// the architectural-readiness fixture covering JSON-Resume+
// extensions.

#import "internal/schema.typ": resume-schema
#import "internal/validate.typ": _validate
#import "internal/coerce.typ": _coerce
#import "internal/errors.typ": _format-report

// Pure validator. Returns a list of {path, message} records for every
// shape or type issue. Empty list means valid. Path is a tuple of
// keys and indices; see _format-path in internal/errors.typ for the
// rendered form.
#let validate-resume(data) = _validate(resume-schema, data, ())

// Pure coercer. Wraps free-text fields (summary, description,
// highlights[], reference) into Typst `content` so renderers consume
// them positionally. Assumes data has passed validate-resume; unknown
// keys (which validate-resume rejects) are dropped silently if
// coerce-resume is called directly on raw input.
#let coerce-resume(data) = _coerce(resume-schema, data)

// Convenience composition. Accepts either a parsed dict or a string
// path (Typst-root-relative, i.e. starts with "/") and produces the
// validated + coerced model. Panics with the combined report on any
// validation issues; callers wanting custom error handling can call
// validate-resume / coerce-resume directly.
//
// String paths are resolved against the typst root because Typst
// interprets relative paths against the file containing the call —
// here that's the @preview/json-resume cache, which is not useful.
// Callers preferring a path relative to their own .typ file should
// call Typst's built-in `json()`:
//
//     #let model = parse-resume(json("resume.json"))
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
  // `assert(false, message: …)` rather than `panic(…)` because Typst's
  // panic-diagnostic repr-escapes the message — embedded newlines come
  // out as literal `\n` and the multi-line report collapses to a
  // single ugly line. `assert(false, message: …)` preserves newlines
  // as real line breaks, so the per-error bullet list renders the way
  // the README sample shows.
  assert(errors.len() == 0, message: _format-report(errors))
  coerce-resume(dict-data)
}
