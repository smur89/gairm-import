// Canonical JSON Resume schema (https://jsonresume.org/schema).
// Derived from the vendored upstream document; see CONTRIBUTING for
// the bump procedure.
//
// `_content-paths` is the deliberate divergence from the source: the
// canonical schema types these free-text fields as `string`, but the
// package wraps them in Typst `content` during coercion for ergonomic
// inline rendering. Open question tracked in #32 — either the
// override earns its keep or it moves to config / disappears.

#import "kinds.typ": (
  str-type, content-type, number-type, array-of, object,
  date-string, uri-string, email-string,
)
#import "json-schema.typ": schema-from-json-schema
#import "lens.typ": lens, lens-get, lens-put

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

// Date fields whose upstream JSON uses `$ref: "#/definitions/iso8601"`
// rather than `format: "date"` — the translator can't pick them up
// from a $ref alone, so they need a lens override. Also includes
// meta.lastModified, which has no format annotation despite an
// ISO-8601 description. Paths with an explicit `format: "date"` are
// translator-emitted and would fail the drift guard if listed here.
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
// the shape change. The guard fires instead, prompting maintainer
// review. Same pattern as _content-paths.
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

#let resume-schema = {
  let base = schema-from-json-schema(json("assets/jsonresume-schema.json"))
  let with-content = _override-fold(base, _content-paths, str-type, content-type, "_content-paths")
  _override-fold(with-content, _date-paths, str-type, date-string, "_date-paths")
}
