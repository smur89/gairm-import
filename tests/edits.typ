// The object edits: add-field, remove-field, set-required and
// unset-required, each at a location (a schema path). Every edit
// leaves a node equal to the one object() builds, so it keeps the
// constructor's invariants, and leaves its input unchanged.

#import "../lib.typ": (
  schema-put, schema-update, add-field, remove-field, set-required,
  unset-required, find-paths, object, map, validate, string, number,
  pointer-to-path,
)
#import "fixtures/resume.typ": resume-schema

#let s = object((a: string(), b: string()), required-keys: ("a",))

// ---- add-field and remove-field --------------------------------------------

#let language-items = ("languages", "items")
#let with-rating = add-field(
  resume-schema,
  language-items + ("rating",),
  number(),
)
#assert.eq(with-rating.shape.languages.elem.shape.rating, number())
#assert.eq(
  validate(with-rating, (languages: ((language: "English", rating: 5),))),
  (),
)
// required: true also requires the field, in the same edit: the same
// node as add-field then set-required.
#assert.eq(
  add-field(s, ("c",), number(), required: true),
  object((a: string(), b: string(), c: number()), required-keys: ("a", "c")),
)
#assert.eq(
  add-field(s, ("c",), number(), required: true),
  set-required(add-field(s, ("c",), number()), (), ("c",)),
)
#assert.eq(
  add-field(s, ("c",), number(), required: false),
  add-field(s, ("c",), number()),
)
// An open object may already require a key it does not declare; it is
// listed once.
#let open-s = map(string(), required-keys: ("c",))
#assert.eq(
  add-field(open-s, ("c",), number(), required: true).required-keys,
  ("c",),
)
// A field's path may end in an int, which names the field it spells,
// as in every schema path, so a path read back from a JSON Pointer
// still folds into the edits.
#let years = object(((str(2024)): string()))
#assert.eq(remove-field(years, (2024,)), object((:)))
#assert.eq(
  add-field(years, pointer-to-path("/2025"), string()),
  object(((str(2024)): string(), (str(2025)): string())),
)
// The new field's schema is checked as schema-put checks its node, so
// `additional: false` closes an object field here too.
#assert.eq(
  add-field(s, ("c",), (..object((d: string())), additional: false)),
  schema-put(
    add-field(s, ("c",), object((d: string()))),
    ("c",),
    (..object((d: string())), additional: false),
  ),
)
#let without-rating = remove-field(with-rating, language-items + ("rating",))
#assert("rating" not in without-rating.shape.languages.elem.shape)
#assert("rating" not in resume-schema.shape.languages.elem.shape)

// remove-field prunes the key from required-keys and from every
// dependency, so an extension can roll back either cleanly.
#let loosened = remove-field(
  object((title: string(), body: string()), required-keys: ("title", "body")),
  ("body",),
)
#assert.eq(loosened, object((title: string()), required-keys: ("title",)))
#let multi = object(
  (a: string(), b: string(), c: string()),
  dependent-required: (a: ("b", "c"), b: ("c",)),
)
#assert.eq(remove-field(multi, ("c",)).dependent-required, (a: ("b",)))
#assert.eq(remove-field(multi, ("a",)).dependent-required, (b: ("c",)))
#assert(
  "dependent-required"
    not in remove-field(
      object((a: string(), b: string()), dependent-required: (a: ("b",))),
      ("b",),
    ),
)

// ---- set-required and unset-required ---------------------------------------

#let basics = ("basics",)
#let schema = object((
  basics: object((name: string(), email: string(), summary: string())),
))
#assert("required-keys" not in schema.shape.basics)

#let strict = set-required(schema, basics, ("name", "email"))
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))
#let errs = validate(strict, (basics: (summary: "hi")))
#assert.eq(errs.map(e => e.path), (("basics", "name"), ("basics", "email")))
#assert(errs.at(0).message.contains("missing required key"))
#assert.eq(
  validate(strict, (
    basics: (name: "Alice", email: "alice@example.com", summary: "hi"),
  )),
  (),
)

// set-required adds to the list, after the keys already required,
// once each; an empty list is a no-op. It undoes unset-required.
#let all-three = set-required(strict, basics, ("summary", "name", "summary"))
#assert.eq(all-three.shape.basics.required-keys, ("name", "email", "summary"))
#assert.eq(set-required(all-three, basics, ()), all-three)
#assert.eq(
  set-required(unset-required(all-three, basics, ("email",)), basics, (
    "email",
  ))
    .shape
    .basics
    .required-keys,
  ("name", "summary", "email"),
)
// Replacing the whole list is a schema-update.
#assert.eq(
  schema-update(all-three, basics, o => (..o, required-keys: ("email",)))
    .shape
    .basics
    .required-keys,
  ("email",),
)

// unset-required relaxes one or several; an empty list is a no-op.
#let mixed = unset-required(all-three, basics, ("email",))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))
#assert.eq(
  validate(mixed, (basics: (:))).map(e => e.path),
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
#assert("required-keys" not in unset-required(root-strict, (), ("basics",)))

// The inputs are unchanged.
#assert("required-keys" not in schema.shape.basics)
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))
#assert.eq(all-three.shape.basics.required-keys, ("name", "email", "summary"))
#assert.eq(mixed.shape.basics.required-keys, ("name", "summary"))

// ---- edits go through object() ---------------------------------------------

// On an open object, required-keys may name keys outside the shape, as
// object() allows.
#let open = object((a: string()), additional: true)
#let req = set-required(open, (), ("a", "extra"))
#assert.eq(req, object(
  (a: string()),
  required-keys: ("a", "extra"),
  additional: true,
))
#assert.eq(validate(req, (a: "x")).map(e => e.path), (("extra",),))
#assert.eq(
  set-required(map(number()), (), ("n",)),
  map(number(), required-keys: ("n",)),
)

// Edits keep dependent-required on an open object.
#let dep = object(
  (a: string()),
  dependent-required: (a: ("x",)),
  additional: true,
)
#assert.eq(add-field(dep, ("b",), number()), object(
  (a: string(), b: number()),
  dependent-required: (a: ("x",)),
  additional: true,
))
#assert.eq(unset-required(set-required(dep, (), ("x",)), (), ("x",)), dep)

// A write into a field rebuilds the parent unchanged.
#let parent = object(
  (a: string(), b: string()),
  required-keys: ("a",),
  dependent-required: (a: ("b",)),
)
#assert.eq(
  schema-put(parent, ("b",), number()),
  object(
    (a: string(), b: number()),
    required-keys: ("a",),
    dependent-required: (a: ("b",)),
  ),
)
#assert.eq(schema-update(parent, (), p => p), parent)
#assert.eq(remove-field(parent, ("b",)), object(
  (a: string()),
  required-keys: ("a",),
))

// A hand-built object may leave `required-keys` out; every edit reads it
// as empty and writes the object back through object().
#let bare = (kind: "object", shape: (a: string()))
#assert.eq(
  add-field(bare, ("b",), number(), required: true),
  object((a: string(), b: number()), required-keys: ("b",)),
)
#assert.eq(remove-field(bare, ("a",)), object((:)))
#assert.eq(set-required(bare, (), ("a",)), object(
  (a: string()),
  required-keys: ("a",),
))

// add-field and remove-field take the field's own path, so find-paths
// results fold straight into remove-field, at any depth.
#let dated = object(
  (
    start: string(format: "date"),
    jobs: object((end: string(format: "date"), title: string())),
  ),
  required-keys: ("start",),
)
#let undated = find-paths(dated, string(format: "date")).fold(
  dated,
  remove-field,
)
#assert.eq(undated, object((jobs: object((title: string())))))
#assert.eq(
  add-field(undated, ("jobs", "end"), string(format: "date")).shape.jobs,
  dated.shape.jobs,
)

// `additional: false` closes an object, as object() reads it.
#assert.eq(
  schema-update(object((a: string()), additional: true), (), o => (
    ..o,
    additional: false,
  )),
  object((a: string())),
)

// An identity edit leaves a hand-built object as it is: object() adds no
// empty `required-keys`.
#let hand = (kind: "object", shape: (a: (kind: "object", shape: (:))))
#assert.eq(schema-update(hand, (), n => n), hand)
