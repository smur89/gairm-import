// The object edits: add-field, remove-field, set-required and
// unset-required, each at a location (a lens or a path). Every edit
// leaves a node equal to the one object() builds, so it keeps the
// constructor's invariants, and leaves its input unchanged.

#import "../lib.typ": (
  lens, lens-put, lens-over, add-field, remove-field, set-required,
  unset-required, resume-schema, object, map, validate, str-type, number-type,
)

// ---- a lens or a path ------------------------------------------------------

#let s = object((a: str-type, b: str-type), required-keys: ("a",))
#assert.eq(
  add-field(s, (), "c", number-type),
  add-field(s, lens(()), "c", number-type),
)
#assert.eq(remove-field(s, (), "b"), remove-field(s, lens(()), "b"))
#assert.eq(
  set-required(s, (), ("a", "b")),
  set-required(s, lens(()), ("a", "b")),
)
#assert.eq(unset-required(s, (), ("a",)), unset-required(s, lens(()), ("a",)))

// ---- add-field and remove-field --------------------------------------------

#let language-items = ("languages", "items")
#let with-rating = add-field(
  resume-schema,
  language-items,
  "rating",
  number-type,
)
#assert.eq(with-rating.shape.languages.elem.shape.rating, number-type)
#assert.eq(
  validate(
    (languages: ((language: "English", rating: 5),)),
    schema: with-rating,
  ),
  (),
)
// required: true also requires the field, in the same edit: the same
// node as add-field then set-required.
#assert.eq(
  add-field(s, (), "c", number-type, required: true),
  object((a: str-type, b: str-type, c: number-type), required-keys: ("a", "c")),
)
#assert.eq(
  add-field(s, (), "c", number-type, required: true),
  set-required(add-field(s, (), "c", number-type), (), ("a", "c")),
)
#assert.eq(
  add-field(s, (), "c", number-type, required: false),
  add-field(s, (), "c", number-type),
)
// An open object may already require a key it does not declare; it is
// listed once.
#let open-s = map(str-type, required-keys: ("c",))
#assert.eq(
  add-field(open-s, (), "c", number-type, required: true).required-keys,
  ("c",),
)
#let without-rating = remove-field(with-rating, language-items, "rating")
#assert("rating" not in without-rating.shape.languages.elem.shape)
#assert("rating" not in resume-schema.shape.languages.elem.shape)

// remove-field prunes the key from required-keys and from every
// dependency, so an extension can roll back either cleanly.
#let loosened = remove-field(
  object((title: str-type, body: str-type), required-keys: ("title", "body")),
  (),
  "body",
)
#assert.eq(loosened, object((title: str-type), required-keys: ("title",)))
#let multi = object(
  (a: str-type, b: str-type, c: str-type),
  dependent-required: (a: ("b", "c"), b: ("c",)),
)
#assert.eq(remove-field(multi, (), "c").dependent-required, (a: ("b",)))
#assert.eq(remove-field(multi, (), "a").dependent-required, (b: ("c",)))
#assert(
  "dependent-required"
    not in remove-field(
      object((a: str-type, b: str-type), dependent-required: (a: ("b",))),
      (),
      "b",
    ),
)

// ---- set-required and unset-required ---------------------------------------

#let basics = ("basics",)
#let schema = object((
  basics: object((name: str-type, email: str-type, summary: str-type)),
))
#assert.eq(schema.shape.basics.required-keys, ())

#let strict = set-required(schema, basics, ("name", "email"))
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))
#let errs = validate((basics: (summary: "hi")), schema: strict)
#assert.eq(errs.map(e => e.path), (("basics", "name"), ("basics", "email")))
#assert(errs.at(0).message.contains("missing required key"))
#assert.eq(
  validate(
    (basics: (name: "Alice", email: "alice@example.com", summary: "hi")),
    schema: strict,
  ),
  (),
)

// set-required replaces the list rather than merging: an empty one
// drops every required key.
#let all-three = set-required(strict, basics, ("name", "email", "summary"))
#assert.eq(all-three.shape.basics.required-keys, ("name", "email", "summary"))
#assert.eq(
  set-required(all-three, basics, ()).shape.basics.required-keys,
  (),
)

// unset-required relaxes one or several; an empty list is a no-op.
#let mixed = unset-required(all-three, basics, ("email",))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))
#assert.eq(
  validate((basics: (:)), schema: mixed).map(e => e.path),
  (("basics", "name"), ("basics", "summary")),
)
#assert.eq(
  unset-required(all-three, basics, ("email", "summary"))
    .shape
    .basics
    .required-keys,
  ("name",),
)
#assert.eq(unset-required(all-three, basics, ()), all-three)

// At the root.
#let root-strict = set-required(schema, (), ("basics",))
#assert.eq(root-strict.required-keys, ("basics",))
#assert.eq(unset-required(root-strict, (), ("basics",)).required-keys, ())

// The inputs are unchanged.
#assert.eq(schema.shape.basics.required-keys, ())
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))
#assert.eq(all-three.shape.basics.required-keys, ("name", "email", "summary"))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))

// ---- edits go through object() ---------------------------------------------

// On an open object, required-keys may name keys outside the shape, as
// object() allows.
#let open = object((a: str-type), additional: true)
#let req = set-required(open, (), ("a", "extra"))
#assert.eq(req, object(
  (a: str-type),
  required-keys: ("a", "extra"),
  additional: true,
))
#assert.eq(validate((a: "x"), schema: req).map(e => e.path), (("extra",),))
#assert.eq(
  set-required(map(number-type), (), ("n",)),
  map(number-type, required-keys: ("n",)),
)

// Edits keep dependent-required on an open object.
#let dep = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(add-field(dep, (), "b", number-type), object(
  (a: str-type, b: number-type),
  dependent-required: (a: ("x",)),
  additional: true,
))
#assert.eq(unset-required(set-required(dep, (), ("x",)), (), ("x",)), dep)

// A write into a field rebuilds the parent unchanged.
#let parent = object(
  (a: str-type, b: str-type),
  required-keys: ("a",),
  dependent-required: (a: ("b",)),
)
#assert.eq(
  lens-put(parent, ("b",), number-type),
  object(
    (a: str-type, b: number-type),
    required-keys: ("a",),
    dependent-required: (a: ("b",)),
  ),
)
#assert.eq(lens-over(parent, (), p => p), parent)
#assert.eq(remove-field(parent, (), "b"), object(
  (a: str-type),
  required-keys: ("a",),
))
