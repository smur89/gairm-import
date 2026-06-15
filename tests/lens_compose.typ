// Without composition `lens-then` would just be a fancy wrapper around
// dict indexing — the test pins that composed and direct lenses are
// observationally equivalent.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-then,
  resume-schema, str-type, number-type,
)

#let basics = lens(("basics",))
#let just-email = lens(("email",))
#let composed = lens-then(basics, just-email)
#let direct = lens(("basics", "email"))

#assert.eq(composed.path, direct.path)
#assert.eq(lens-get(composed, resume-schema), lens-get(direct, resume-schema))
#assert.eq(lens-get(composed, resume-schema), str-type)

#let via-composed = lens-put(composed, resume-schema, number-type)
#let via-direct = lens-put(direct, resume-schema, number-type)
#assert.eq(via-composed, via-direct)

// Compose across an object→array→object boundary via "items".
#let work = lens(("work",))
#let items = lens(("items",))
#let highlights = lens(("highlights",))
#let work-highlights = lens-then(lens-then(work, items), highlights)
#assert.eq(work-highlights.path, ("work", "items", "highlights"))
#assert.eq(lens-get(work-highlights, resume-schema).kind, "array")
