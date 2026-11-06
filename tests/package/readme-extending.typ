// Mirrors README.md, "Building an extension schema" and "Targeted edits
// with lenses": the edits the README shows keep what they don't touch.
// The asserts are ours.
#import "@preview/gairm-import:0.0.0": (
  resume-schema, resume-schema-strict, lens-get, lens-put, lens-over, add-field,
  array-of, content-type, str-type, validate,
)

// add-field keeps upstream's open top level.
#let altacv-schema = add-field(
  resume-schema,
  (),
  "focusAreas",
  array-of(content-type),
)
#assert.eq(altacv-schema.additional, resume-schema.additional)
#assert.eq(validate((focusAreas: ("a",), extra: 1), schema: altacv-schema), ())

// The plain-summary edit changes something: strict has content there.
#assert.eq(
  lens-get(resume-schema-strict, ("basics", "summary")).kind,
  "content",
)
#let plain-summary = lens-put(
  resume-schema-strict,
  ("basics", "summary"),
  str-type,
)
#assert.eq(lens-get(plain-summary, ("basics", "summary")), str-type)

// Spreading `meta` keeps its `additional`.
#let with-extra-meta = lens-over(
  resume-schema,
  ("meta",),
  meta => (..meta, shape: (..meta.shape, source: str-type)),
)
#let meta = lens-get(with-extra-meta, ("meta",))
#assert.eq(meta.shape.source, str-type)
#assert.eq(meta.additional, lens-get(resume-schema, ("meta",)).additional)
