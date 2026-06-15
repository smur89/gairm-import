// Pins the get/put round-trip and the lens record shape.

#import "../lib.typ": (
  lens, lens-get, lens-put,
  resume-schema, str-type, content-type, number-type,
)

#let basics = lens(("basics",))
#assert.eq(basics.path, ("basics",))
#assert.eq(basics.kind, "lens")
#assert.eq(lens-get(basics, resume-schema).kind, "object")
#assert("name" in lens-get(basics, resume-schema).shape)

#let email = lens(("basics", "email"))
#assert.eq(lens-get(email, resume-schema), str-type)

#let widened = lens-put(email, resume-schema, content-type)
#assert.eq(lens-get(email, widened), content-type)
// Sibling sections must survive the put untouched.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.name, str-type)

// Immutability of the original after put.
#assert.eq(lens-get(email, resume-schema), str-type)
