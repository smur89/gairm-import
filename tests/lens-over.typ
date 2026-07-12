// The real extension use case from issue #26: add `rating` to every
// language entry — a deep edit into schema.languages.elem.shape.

#import "../lib.typ": (
  lens, lens-over, resume-schema, object, str-type, number-type, validate,
  lens-get, kind-at,
)

#let language-items = lens(("languages", "items"))
#let with-rating = lens-over(
  language-items,
  resume-schema,
  lang => object((..lang.shape, rating: number-type)),
)

#let sample = (
  languages: ((language: "English", fluency: "native", rating: 5),),
)
#assert.eq(validate(sample, schema: with-rating), ())

// Edit is localised to the lensed value — the canonical schema's own
// `shape.languages.items` still has no `rating` declared. (Upstream
// JSON Resume sets `additionalProperties: true` on language items, so
// the canonical schema accepts extra fields at runtime; this assertion
// targets the schema declaration, not the runtime acceptance.)
#let canonical-language-shape = lens-get(language-items, resume-schema).shape
#assert("rating" not in canonical-language-shape)
#let with-rating-shape = lens-get(language-items, with-rating).shape
#assert.eq(with-rating-shape.rating, number-type)
