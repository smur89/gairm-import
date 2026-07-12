// Pins unset-required: symmetric relaxation of an object's
// required-keys, panics on stale "still required" assumptions,
// validate stops emitting "missing required key" once relaxed.

#import "../lib.typ": (
  lens, set-required, unset-required, object, validate, str-type,
)

#let basics = object((name: str-type, email: str-type, summary: str-type))
#let schema = object((basics: basics))

#let basics-lens = lens(("basics",))
#let identity = lens(())

// ---- happy: relax one of several -----------------------------------

#let strict = set-required(schema, basics-lens, ("name", "email", "summary"))
#assert.eq(strict.shape.basics.required-keys, ("name", "email", "summary"))

#let mixed = unset-required(strict, basics-lens, ("email",))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))

// validate stops emitting missing-required for the relaxed key but
// still emits it for the still-required ones.
#let errs = validate((basics: (:)), schema: mixed)
#assert.eq(errs.len(), 2)
#let paths = errs.map(e => e.path)
#assert(("basics", "name") in paths)
#assert(("basics", "summary") in paths)
#assert(("basics", "email") not in paths)

// ---- happy: relax multiple at once ---------------------------------

#let relaxed = unset-required(strict, basics-lens, ("email", "summary"))
#assert.eq(relaxed.shape.basics.required-keys, ("name",))

// ---- empty keys list is a documented no-op -------------------------

#let unchanged = unset-required(strict, basics-lens, ())
#assert.eq(unchanged.shape.basics.required-keys, ("name", "email", "summary"))

// ---- identity lens relaxes the root's required-keys ----------------

#let root-strict = set-required(schema, identity, ("basics",))
#let root-relaxed = unset-required(root-strict, identity, ("basics",))
#assert.eq(root-relaxed.required-keys, ())

// ---- immutability of the input -------------------------------------

#assert.eq(strict.shape.basics.required-keys, ("name", "email", "summary"))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))

// Panic-message pins live in lens-panic-messages.typ alongside
// set-required / add-field / remove-field counterparts.
