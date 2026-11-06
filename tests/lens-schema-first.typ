// Pins the schema-first argument order, the `(lens: path)` lens shape,
// and a path array standing in for a lens wherever a location is taken.

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-over, lens-then, add-field, remove-field,
  set-required, unset-required, kind-at, paths-of-kind, resume-schema, object,
  str-type, content-type, number-type, uri-string,
)

// A lens is its own shape, with no `kind` key.
#let name = lens(("basics", "name"))
#assert.eq(name, (lens: ("basics", "name")))
#assert("kind" not in name)

// lens-get / lens-put / lens-over: schema first, a lens or a path.
#assert.eq(lens-get(resume-schema, name), str-type)
#assert.eq(lens-get(resume-schema, ("basics", "name")), str-type)
#assert.eq(lens-get(resume-schema, ()), resume-schema)

#let widened = lens-put(resume-schema, name, content-type)
#assert.eq(lens-get(widened, name), content-type)
#assert.eq(lens-put(resume-schema, ("basics", "name"), content-type), widened)
#assert.eq(widened.shape.work, resume-schema.shape.work)

#assert.eq(lens-over(resume-schema, name, _ => content-type), widened)
#assert.eq(
  lens-over(resume-schema, ("basics", "name"), _ => content-type),
  widened,
)

// lens-then takes either form and returns a lens.
#assert.eq(lens-then(lens(("basics",)), lens(("name",))), name)
#assert.eq(lens-then(("basics",), ("name",)), name)
#assert.eq(lens-then(lens(("basics",)), ("name",)), name)
#assert.eq(lens-then(("basics",), lens(("name",))), name)
#assert.eq(lens-then((), ()), lens(()))

// The edit functions take a lens or a path.
#let s = object((a: str-type, b: str-type), required-keys: ("a",))
#assert.eq(
  add-field(s, (), "c", number-type),
  add-field(s, lens(()), "c", number-type),
)
#assert.eq(add-field(s, (), "c", number-type).shape.c, number-type)
#assert.eq(remove-field(s, (), "b"), remove-field(s, lens(()), "b"))
#assert.eq(
  set-required(s, (), ("a", "b")),
  set-required(s, lens(()), ("a", "b")),
)
#assert.eq(unset-required(s, (), ("a",)), unset-required(s, lens(()), ("a",)))

// kind-at takes a lens as well as a path.
#assert.eq(kind-at(resume-schema, ("basics", "name")), "str")
#assert.eq(kind-at(resume-schema, name), "str")

// The schema-first order pipes through `.fold`, and paths-of-kind
// output plugs straight in without wrapping each path in a lens.
#let plain = paths-of-kind(resume-schema, uri-string).fold(
  resume-schema,
  (acc, p) => lens-put(acc, p, str-type),
)
#assert.eq(paths-of-kind(plain, uri-string), ())
