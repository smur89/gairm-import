// add-field / remove-field convenience helpers operating on object
// schemas targeted by a parent lens.

#import "../lib.typ": (
  lens, add-field, remove-field, resume-schema, object,
  str-type, number-type, validate,
)

#let language-items = lens(("languages", "items"))
#let with-rating = add-field(resume-schema, language-items, "rating", number-type)

// rating is now an accepted key on language entries.
#assert("rating" in with-rating.shape.languages.elem.shape)
#assert.eq(with-rating.shape.languages.elem.shape.rating, number-type)
#assert.eq(
  validate(
    (languages: ((language: "English", rating: 5),)),
    schema: with-rating,
  ),
  (),
)

// Round-trip: remove the field, verify it's gone.
#let without-rating = remove-field(with-rating, language-items, "rating")
#assert("rating" not in without-rating.shape.languages.elem.shape)

// remove-field also strips the key from required-keys so an extension
// schema can roll back a required-keys decision cleanly.
#let strict = object(
  (title: str-type, body: str-type),
  required-keys: ("title", "body"),
)
#let identity = lens(())
#let loosened = remove-field(strict, identity, "body")
#assert.eq(loosened.required-keys, ("title",))
#assert("body" not in loosened.shape)

// Original schema unchanged after add-field / remove-field —
// confirms the functional contract.
#assert("rating" not in resume-schema.shape.languages.elem.shape)
