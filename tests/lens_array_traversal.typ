// "items" enters an array schema's element. The whole point of the
// segment is to make `("work", "items", "highlights")` read as "the
// highlights field of each work entry" — pin both the get and the
// schema kinds at each step.

#import "../lib.typ": (
  lens, lens-get, lens-put,
  resume-schema, content-type,
)

#let work = lens(("work",))
#assert.eq(lens-get(work, resume-schema).kind, "array")

#let work-items = lens(("work", "items"))
#assert.eq(lens-get(work-items, resume-schema).kind, "object")
// Work item objects expose the full work-record shape.
#assert("position" in lens-get(work-items, resume-schema).shape)
#assert("highlights" in lens-get(work-items, resume-schema).shape)

#let work-highlights = lens(("work", "items", "highlights"))
#assert.eq(lens-get(work-highlights, resume-schema).kind, "array")
#assert.eq(lens-get(work-highlights, resume-schema).elem, content-type)

// Putting through the array boundary replaces the inner element
// schema without touching the array wrapper.
#let widened = lens-put(work-highlights, resume-schema, content-type)
#assert.eq(widened.shape.work.kind, "array")
#assert.eq(widened.shape.work.elem.kind, "object")
