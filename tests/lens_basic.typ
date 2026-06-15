// Single- and multi-segment lenses: get reads, put replaces, both
// against the canonical schema. Pins the get/put round-trip and the
// shape of the returned lens record.

#import "../lib.typ": (
  lens, lens-get, lens-put,
  resume-schema, str-type, content-type, number-type,
)

// Single-segment lens targets a top-level section.
#let basics = lens(("basics",))
#assert.eq(basics.path, ("basics",))
#assert.eq(basics.kind, "lens")
#assert.eq(lens-get(basics, resume-schema).kind, "object")
#assert("name" in lens-get(basics, resume-schema).shape)

// Multi-segment lens drills into a nested object.
#let email = lens(("basics", "email"))
#assert.eq(lens-get(email, resume-schema), str-type)

// put replaces the targeted node and rebuilds the schema outward.
#let widened = lens-put(email, resume-schema, content-type)
#assert.eq(lens-get(email, widened), content-type)
// Surrounding sections survive unchanged.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.name, str-type)

// Immutability: the original schema is untouched by put.
#assert.eq(lens-get(email, resume-schema), str-type)
