// Pins lens edits on objects going through object(): set-required
// accepts what object() accepts on an open object, and every edit
// leaves a node equal to the one the constructor builds.

#import "../lib.typ": (
  lens, lens-put, lens-over, add-field, set-required, unset-required,
  remove-field, object, map, validate, str-type, number-type,
)

// ---- set-required on an open object ---------------------------------

// `additional: true` lets required-keys name keys outside the shape,
// as object() does.
#let open = object((a: str-type), additional: true)
#let req = set-required(open, lens(()), ("a", "extra"))
#assert.eq(req, object(
  (a: str-type),
  required-keys: ("a", "extra"),
  additional: true,
))
#assert.eq(validate((a: "x"), schema: req).map(e => e.path), (("extra",),))

// So does an additional schema.
#assert.eq(
  set-required(map(number-type), lens(()), ("n",)),
  map(number-type, required-keys: ("n",)),
)

// ---- edits keep dependent-required on an open object -----------------

#let dep = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(add-field(dep, lens(()), "b", number-type), object(
  (a: str-type, b: number-type),
  dependent-required: (a: ("x",)),
  additional: true,
))
#assert.eq(
  unset-required(set-required(dep, lens(()), ("x",)), lens(()), ("x",)),
  dep,
)

// ---- a write into a field rebuilds the parent unchanged --------------

#let parent = object(
  (a: str-type, b: str-type),
  required-keys: ("a",),
  dependent-required: (a: ("b",)),
)
#assert.eq(
  lens-put(lens(("b",)), parent, number-type),
  object(
    (a: str-type, b: number-type),
    required-keys: ("a",),
    dependent-required: (a: ("b",)),
  ),
)
#assert.eq(lens-over(lens(()), parent, p => p), parent)
#assert.eq(remove-field(parent, lens(()), "b"), object(
  (a: str-type),
  required-keys: ("a",),
))
