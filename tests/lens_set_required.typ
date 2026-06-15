// Pins set-required: lens-driven required-keys replacement, validate
// emits "missing required key" from the new list, immutability holds,
// typos surface as construction-time panics.

#import "../lib.typ": (
  lens, set-required, object, validate,
  str-type, number-type,
)

// ---- happy: empty → required ---------------------------------------

#let basics = object((name: str-type, email: str-type, summary: str-type))
#let schema = object((basics: basics))
#assert.eq(schema.shape.basics.required-keys, ())

#let identity = lens(())
#let basics-lens = lens(("basics",))

#let strict = set-required(schema, basics-lens, ("name", "email"))
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))

#let errs = validate((basics: (summary: "hi")), schema: strict)
#assert.eq(errs.len(), 2)
#let paths = errs.map(e => e.path)
#assert(("basics", "name") in paths)
#assert(("basics", "email") in paths)
#assert(errs.at(0).message.contains("missing required key"))

#assert.eq(
  validate(
    (basics: (name: "Alice", email: "alice@example.com", summary: "hi")),
    schema: strict,
  ),
  (),
)

// ---- replacing an existing required-keys list ----------------------

#let stricter = set-required(strict, basics-lens, ("name", "email", "summary"))
#assert.eq(stricter.shape.basics.required-keys, ("name", "email", "summary"))

// Replacement, not merge — passing the empty tuple drops every required key.
#let relaxed = set-required(stricter, basics-lens, ())
#assert.eq(relaxed.shape.basics.required-keys, ())

// ---- identity lens replaces the root's required-keys ---------------

#let root-strict = set-required(schema, identity, ("basics",))
#assert.eq(root-strict.required-keys, ("basics",))

// ---- immutability of the input -------------------------------------

#assert.eq(schema.shape.basics.required-keys, ())
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))

// Panic-message pins live in lens_panic_messages.typ alongside the
// add-field / remove-field counterparts.
