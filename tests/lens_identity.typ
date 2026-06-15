// Empty path = identity lens. get returns the input; put replaces it
// wholesale. Pinning this makes the empty-path case a documented
// no-op rather than a corner with surprising behaviour.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-over, lens-then,
  resume-schema, str-type,
)

#let identity = lens(())
#assert.eq(identity.path, ())
#assert.eq(lens-get(identity, resume-schema), resume-schema)

// put replaces the schema wholesale — useful when a caller wants to
// reuse a code path that takes a lens but actually means "the whole
// schema".
#assert.eq(lens-put(identity, resume-schema, str-type), str-type)

// over against the identity lens is just function application.
#assert.eq(lens-over(identity, resume-schema, _ => str-type), str-type)

// Identity composed with another lens equals the other lens.
#let email = lens(("basics", "email"))
#assert.eq(lens-then(identity, email).path, email.path)
#assert.eq(lens-then(email, identity).path, email.path)
