// json-resume — load and validate canonical JSON Resume data for any
// Typst CV template. Strict to the published schema at
// https://jsonresume.org/schema. Renderer-specific extensions (labels,
// theme preferences, header decorations, …) are out of scope — they
// belong in the consuming template, layered on top of the normalised
// dict returned here.

// Read `path` as a JSON Resume document and return the validated,
// content-coerced dict.
#let read-resume(path) = {
  panic(
    "json-resume: read-resume is not yet implemented — track progress at " +
      "https://github.com/smur89/typst-json-resume",
  )
}

// Validate `data` against the canonical JSON Resume schema and coerce
// string fields that renderers consume as `content` (e.g. `summary`,
// `highlights[]`, `description`).
#let parse-resume(data) = {
  panic(
    "json-resume: parse-resume is not yet implemented — track progress at " +
      "https://github.com/smur89/typst-json-resume",
  )
}
