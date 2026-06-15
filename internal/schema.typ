// Canonical JSON Resume schema (https://jsonresume.org/schema).
//
// `resume-schema` is a faithful translation of the vendored upstream
// JSON Schema document — every kind comes from the source, nothing
// is rewritten. `resume-schema-strict` layers two opinions on top
// via the lens API for callers who want them: free-text fields
// wrapped as Typst `content` for inline rendering, and iso8601
// `$ref` fields lifted to `date-string` for regex validation. Both
// schemas are exported; pick via the `schema:` keyword on
// `parse` / `validate` / `coerce`.

#import "kinds.typ": (
  str-type, content-type, number-type, array-of, object,
  date-string, uri-string, email-string,
)
#import "json-schema.typ": schema-from-json-schema
#import "lens.typ": lens, lens-get, lens-put

#let resume-schema = schema-from-json-schema(json("assets/jsonresume-schema.json"))

// Free-text fields the strict variant wraps as Typst `content` for
// inline rendering. Canonical schema types these as `string`; the
// override is the package's Typst-renderer opinion, not validation.
#let _content-paths = (
  ("basics", "summary"),
  ("work", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("volunteer", "items", "highlights", "items"),
  ("awards", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
)

// Date fields whose upstream uses `$ref: "#/definitions/iso8601"`
// rather than `format: "date"` — the translator can't pick those up
// from a $ref alone. Also includes meta.lastModified, which has no
// format annotation despite an ISO-8601 description.
#let _date-paths = (
  ("work", "items", "startDate"),
  ("work", "items", "endDate"),
  ("volunteer", "items", "startDate"),
  ("volunteer", "items", "endDate"),
  ("education", "items", "startDate"),
  ("education", "items", "endDate"),
  ("awards", "items", "date"),
  ("publications", "items", "releaseDate"),
  ("projects", "items", "startDate"),
  ("projects", "items", "endDate"),
  ("meta", "lastModified"),
)

// Pre-condition guard turns silent upstream drift into a load-time
// panic: if a future schema bump changes one of these fields away
// from the expected source kind, the override would otherwise mask
// the shape change. The guard fires instead.
#let _override-fold(schema, paths, expected-source, replacement, list-name) = {
  paths.fold(schema, (s, p) => {
    let l = lens(p)
    let current = lens-get(l, s)
    assert(
      current == expected-source,
      message: "json-resume: " + list-name + " must target " +
        repr(expected-source.kind) + " leaves only — " + repr(p) +
        " is now " + repr(current.kind) + ". Audit upstream schema bump.",
    )
    lens-put(l, s, replacement)
  })
}

#let resume-schema-strict = {
  let with-content = _override-fold(
    resume-schema, _content-paths, str-type, content-type, "_content-paths",
  )
  _override-fold(
    with-content, _date-paths, str-type, date-string, "_date-paths",
  )
}
