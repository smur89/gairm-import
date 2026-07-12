// The "items" segment is what makes ("work", "items", "highlights")
// read as "the highlights field of each work entry" — pin the get
// and the schema kinds at each step.

#import "../lib.typ": (
  lens, lens-get, lens-put,
  resume-schema, content-type, str-type,
)

#let work = lens(("work",))
#assert.eq(lens-get(work, resume-schema).kind, "array")

#let work-items = lens(("work", "items"))
#assert.eq(lens-get(work-items, resume-schema).kind, "object")
#assert("position" in lens-get(work-items, resume-schema).shape)
#assert("highlights" in lens-get(work-items, resume-schema).shape)

#let work-highlights = lens(("work", "items", "highlights"))
#assert.eq(lens-get(work-highlights, resume-schema).kind, "array")
// Faithful default keeps highlights[].items as plain str; the strict
// variant is what overrides it to content. The lens just walks.
#assert.eq(lens-get(work-highlights, resume-schema).elem, str-type)

// Put through the array boundary replaces the inner element schema
// without disturbing the array wrapper.
#let widened = lens-put(work-highlights, resume-schema, content-type)
#assert.eq(widened.shape.work.kind, "array")
#assert.eq(widened.shape.work.elem.kind, "object")
// And the targeted node is actually the replacement value.
#assert.eq(widened.shape.work.elem.shape.highlights, content-type)
#assert.eq(lens-get(work-highlights, widened), content-type)
