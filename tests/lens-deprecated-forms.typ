// The forms deprecated in favour of schema-first and `(lens: path)`,
// accepted until 1.0: the lens-first order of lens-get / lens-put /
// lens-over, and the old `(kind: "lens", path: …)` lens shape wherever
// a location is taken. Each must equal its new spelling.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-over, lens-then, add-field, remove-field,
  set-required, unset-required, kind-at, resume-schema, object, str-type,
  content-type, number-type,
)

#let old = (kind: "lens", path: ("basics", "name"))
#let new = lens(("basics", "name"))
#let path = ("basics", "name")

// Lens-first order, with any location form.
#for at in (old, new, path) {
  assert.eq(lens-get(at, resume-schema), lens-get(resume-schema, new))
  assert.eq(
    lens-put(at, resume-schema, content-type),
    lens-put(resume-schema, new, content-type),
  )
  assert.eq(
    lens-over(at, resume-schema, _ => content-type),
    lens-over(resume-schema, new, _ => content-type),
  )
}

// The old lens shape in the new order, and everywhere else a location
// is taken.
#assert.eq(lens-get(resume-schema, old), str-type)
#assert.eq(kind-at(resume-schema, old), "string")
#assert.eq(
  lens-then((kind: "lens", path: ("basics",)), (kind: "lens", path: ("name",))),
  new,
)

#let s = object((a: str-type, b: str-type), required-keys: ("a",))
#let root = (kind: "lens", path: ())
#assert.eq(
  add-field(s, root, "c", number-type),
  add-field(s, (), "c", number-type),
)
#assert.eq(remove-field(s, root, "b"), remove-field(s, (), "b"))
#assert.eq(set-required(s, root, ("b",)), set-required(s, (), ("b",)))
#assert.eq(unset-required(s, root, ("a",)), unset-required(s, (), ("a",)))
