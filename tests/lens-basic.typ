// Pins the get/put round-trip and the lens record shape.

#import "../lib.typ": (
  lens, lens-get, lens-put, resume-schema, str-type, content-type, number-type,
)

#let basics = lens(("basics",))
#assert.eq(basics.path, ("basics",))
#assert.eq(basics.kind, "lens")
#assert.eq(lens-get(basics, resume-schema).kind, "object")
#assert("name" in lens-get(basics, resume-schema).shape)

#let name = lens(("basics", "name"))
#assert.eq(lens-get(name, resume-schema), str-type)

#let widened = lens-put(name, resume-schema, content-type)
#assert.eq(lens-get(name, widened), content-type)
// Sibling sections must survive the put untouched.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.label, str-type)

// Immutability of the original after put.
#assert.eq(lens-get(name, resume-schema), str-type)
