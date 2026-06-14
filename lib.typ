// json-resume — load and validate canonical JSON Resume data for any
// Typst CV template. Strict to the published schema at
// https://jsonresume.org/schema. Renderer-specific extensions (labels,
// theme preferences, header decorations, …) are out of scope — they
// belong in the consuming template, layered on top of the normalised
// dict returned here.

#import "internal/schema.typ": resume-schema
#import "internal/validate.typ": _validate
#import "internal/coerce.typ": _coerce
#import "internal/errors.typ": _format-report

// Step 1 — read raw JSON from disk. Returns a dict with JSON-native
// types (strings, numbers, arrays, dicts). Validation and coercion
// are separate steps; see validate-resume and coerce-resume below.
//
// `path` must be Typst-root-relative, i.e. start with "/". Typst
// resolves relative paths against the file containing the call —
// inside this package that would be the @preview/json-resume cache,
// which is not useful — so we require absolute paths from the
// project's typst root. Callers who prefer a path relative to their
// own .typ file can use Typst's built-in `json()` directly:
//
//     #let raw = json("resume.json")
//     #let model = parse-resume(raw)
#let read-resume(path) = {
  if type(path) != str {
    panic(
      "json-resume: read-resume expected a string path, got " +
        repr(path) + ".",
    )
  }
  if not path.starts-with("/") {
    panic(
      "json-resume: read-resume requires a path starting with \"/\" " +
        "(resolved from the typst root). Got: " + repr(path) + ". " +
        "To use a path relative to your own .typ file, call Typst's " +
        "json() directly: parse-resume(json(" + repr(path) + ")).",
    )
  }
  json(path)
}

// Step 2 — pure validator. Returns a list of {path, message} records
// for every shape or type issue. Empty list means valid.
#let validate-resume(data) = _validate(resume-schema, data, ())

// Step 3 — pure coercer. Wraps free-text fields (summary, description,
// highlights[], reference) into Typst `content` so renderers consume
// them positionally. Assumes data has passed validate-resume;
// behaviour on invalid input is unspecified.
#let coerce-resume(data) = _coerce(resume-schema, data)

// Convenience composition. Validates first, panics with the combined
// report if there are issues, otherwise coerces. Callers who want to
// handle errors themselves can call validate-resume / coerce-resume
// directly.
#let parse-resume(data) = {
  let errors = validate-resume(data)
  if errors.len() > 0 {
    panic(_format-report(errors))
  }
  coerce-resume(data)
}
