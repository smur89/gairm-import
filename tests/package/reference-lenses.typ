// Mirrors REFERENCE.md, "Lenses and edits": each example, and that the
// edits keep what they don't touch. The calls match REFERENCE.md; the
// asserts are ours.
#import "@preview/gairm-import:0.0.0": *

// A renderer-specific top-level field.
#let altacv-schema = add-field(
  resume-schema,
  (),
  "focusAreas",
  array-of(content-type),
)
#assert.eq(altacv-schema.additional, resume-schema.additional)
#assert.eq(validate((focusAreas: ("a",), extra: 1), schema: altacv-schema), ())
// Spreading the shape into a new object closes the top level.
#assert.ne(
  validate(
    (extra: 1),
    schema: object((..resume-schema.shape, focusAreas: array-of(content-type))),
  ),
  (),
)

// A numeric rating on every language entry.
#let with-rating = add-field(
  resume-schema,
  ("languages", "items"),
  "rating",
  number(),
)
#assert.eq(lens-get(with-rating, ("languages", "items", "rating")), number())

// Back to a plain-string summary in the strict schema.
#assert.eq(
  lens-get(resume-schema-strict, ("basics", "summary")).kind,
  "content",
)
#let plain-summary = lens-put(
  resume-schema-strict,
  ("basics", "summary"),
  string(),
)
#assert.eq(lens-get(plain-summary, ("basics", "summary")), string())

// Spreading `meta` keeps its `additional`.
#let with-extra-meta = lens-over(
  resume-schema,
  ("meta",),
  meta => (..meta, shape: (..meta.shape, source: string())),
)
#let meta = lens-get(with-extra-meta, ("meta",))
#assert.eq(meta.shape.source, string())
#assert.eq(meta.additional, lens-get(resume-schema, ("meta",)).additional)

// Require basics.name and basics.email, then relax email again.
#let strict-basics = set-required(
  resume-schema,
  ("basics",),
  (
    "name",
    "email",
  ),
)
#let name-only = unset-required(strict-basics, ("basics",), ("email",))
#assert.eq(lens-get(strict-basics, ("basics",)).required-keys, (
  "name",
  "email",
))
#assert.eq(lens-get(name-only, ("basics",)).required-keys, ("name",))

// A location is a path or `(lens: path)`, and paths join with `+`.
#assert.eq(
  lens-get(resume-schema, (lens: ("work",) + ("items", "highlights"))),
  lens-get(resume-schema, ("work", "items", "highlights")),
)

// Every uri field to a corporate pattern.
#let corporate-uri = string(
  pattern: "^https://(corp|docs)\.example\.com/",
  expected: "a corporate URL",
)
#let corporate-schema = paths-of-kind(
  resume-schema,
  string(format: "uri"),
).fold(
  resume-schema,
  (schema, path) => lens-put(schema, path, corporate-uri),
)
#assert.eq(paths-of-kind(corporate-schema, string(format: "uri")), ())
#assert.eq(lens-get(corporate-schema, ("basics", "url")), corporate-uri)
