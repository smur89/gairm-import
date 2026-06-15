// `lens-over` applies a function to the targeted node. Exercises the
// real extension use case from issue #26: adding a `rating` field to
// every language entry (a deep edit reaching schema.languages.elem.shape).

#import "../lib.typ": (
  lens, lens-over,
  resume-schema, object, str-type, number-type, validate,
)

#let language-items = lens(("languages", "items"))
#let with-rating = lens-over(
  language-items,
  resume-schema,
  lang => object((..lang.shape, rating: number-type)),
)

// The transformed schema accepts the rating field; the canonical
// schema would have rejected it as unknown.
#let sample = (
  languages: ((language: "English", fluency: "native", rating: 5),),
)
#assert.eq(validate(sample, schema: with-rating), ())

// And the canonical schema still rejects it — proving the edit is
// localised to the new schema value, not a global mutation.
#let errors = validate(sample, schema: resume-schema)
#assert(errors.len() > 0)
#assert.eq(errors.at(0).path, ("languages", 0, "rating"))
#assert(errors.at(0).message.contains("unknown key"))
