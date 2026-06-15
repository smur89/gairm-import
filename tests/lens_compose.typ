// `lens-then` composition concatenates paths — composing two lenses
// produces the same lens as constructing one with the joined path.
// Without that, "lens" would just be a fancy wrapper around dict
// indexing.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-then,
  resume-schema, str-type, number-type,
)

#let basics = lens(("basics",))
#let just-email = lens(("email",))
#let composed = lens-then(basics, just-email)
#let direct = lens(("basics", "email"))

// Composition is path concatenation.
#assert.eq(composed.path, direct.path)
#assert.eq(lens-get(composed, resume-schema), lens-get(direct, resume-schema))
#assert.eq(lens-get(composed, resume-schema), str-type)

// Put through the composed lens behaves identically to the direct one.
#let via-composed = lens-put(composed, resume-schema, number-type)
#let via-direct = lens-put(direct, resume-schema, number-type)
#assert.eq(via-composed, via-direct)

// Three-way composition reaches into the array-element schema via
// "items", proving compose still works across array boundaries.
#let work = lens(("work",))
#let items = lens(("items",))
#let highlights = lens(("highlights",))
#let work-highlights = lens-then(lens-then(work, items), highlights)
#assert.eq(work-highlights.path, ("work", "items", "highlights"))
#assert.eq(lens-get(work-highlights, resume-schema).kind, "array")
