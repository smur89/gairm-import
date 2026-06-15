// Pins the identity lens as a documented no-op rather than a corner
// with surprising behaviour.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-over, lens-then,
  resume-schema, str-type,
)

#let identity = lens(())
#assert.eq(identity.path, ())
#assert.eq(lens-get(identity, resume-schema), resume-schema)

// Wholesale replace via identity — supports call sites that take a
// lens generically but sometimes mean "the whole schema".
#assert.eq(lens-put(identity, resume-schema, str-type), str-type)

#assert.eq(lens-over(identity, resume-schema, _ => str-type), str-type)

#let name = lens(("basics", "name"))
#assert.eq(lens-then(identity, name).path, name.path)
#assert.eq(lens-then(name, identity).path, name.path)
