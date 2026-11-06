// Lenses: a location in a schema, as `(lens: path)` or the bare path
// array, read with lens-get, replaced with lens-put, mapped with
// lens-over and joined with lens-then. Each takes the schema first, so
// edits pipe through `.fold`. A segment enters an object field, an
// array's "items", an object's "additionalProperties", a union member
// by index, or a `not` member by "not".

#import "../lib.typ": (
  lens, lens-get, lens-put, lens-over, lens-then, kind-at, paths-of-kind,
  validate, resume-schema, resume-schema-strict, object, array-of, str-type,
  content-type, number-type, uri-string, date-string, datetime-string, any-of,
  one-of, not-of,
)

// ---- the lens ----------------------------------------------------------

// A lens is its own shape, with no `kind` key.
#let name = lens(("basics", "name"))
#assert.eq(name, (lens: ("basics", "name")))
#assert("kind" not in name)
#assert.eq(lens(()), (lens: ()))

// ---- lens-get --------------------------------------------------------------

#assert.eq(lens-get(resume-schema, name), str-type)
#assert.eq(lens-get(resume-schema, ("basics", "name")), str-type)
#let basics = lens-get(resume-schema, ("basics",))
#assert.eq(basics.kind, "object")
#assert("name" in basics.shape)
// The empty path is the identity.
#assert.eq(lens-get(resume-schema, ()), resume-schema)
#assert.eq(lens-get(resume-schema, lens(())), resume-schema)

// "items" enters an array's elements: ("work", "items", "highlights")
// is the highlights field of each work entry.
#assert.eq(lens-get(resume-schema, ("work",)).kind, "array")
#let work-item = lens-get(resume-schema, ("work", "items"))
#assert.eq(work-item.kind, "object")
#assert("position" in work-item.shape)
#assert("highlights" in work-item.shape)
// The faithful schema keeps highlights as plain str; the strict variant
// is what makes them content. The lens just walks.
#assert.eq(
  lens-get(resume-schema, ("work", "items", "highlights")),
  array-of(str-type),
)

// ---- lens-put and lens-over ------------------------------------------------

#let widened = lens-put(resume-schema, name, content-type)
#assert.eq(lens-get(widened, name), content-type)
#assert.eq(lens-put(resume-schema, ("basics", "name"), content-type), widened)
#assert.eq(lens-over(resume-schema, name, _ => content-type), widened)
#assert.eq(
  lens-over(resume-schema, ("basics", "name"), _ => content-type),
  widened,
)
// Siblings survive untouched, and the original is unchanged.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.label, str-type)
#assert.eq(lens-get(resume-schema, name), str-type)

// The identity lens replaces the whole schema, for call sites that take
// a lens generically but sometimes mean "the whole schema".
#assert.eq(lens-put(resume-schema, (), str-type), str-type)
#assert.eq(lens-over(resume-schema, lens(()), _ => str-type), str-type)

// A put through an array replaces the element's field and keeps the
// array and object wrappers.
#let rich = lens-put(
  resume-schema,
  ("work", "items", "highlights", "items"),
  content-type,
)
#assert.eq(rich.shape.work.kind, "array")
#assert.eq(rich.shape.work.elem.kind, "object")
#assert.eq(rich.shape.work.elem.shape.highlights, array-of(content-type))

// The extension use case from #26: add `rating` to every language entry,
// a deep edit into languages' items. Only the lensed node changes.
#let language-items = lens(("languages", "items"))
#let with-rating = lens-over(
  resume-schema,
  language-items,
  lang => object((..lang.shape, rating: number-type)),
)
#assert.eq(
  validate(
    (languages: ((language: "English", fluency: "native", rating: 5),)),
    schema: with-rating,
  ),
  (),
)
#assert.eq(lens-get(with-rating, language-items).shape.rating, number-type)
#assert("rating" not in lens-get(resume-schema, language-items).shape)

// The schema-first order pipes through `.fold`, and paths-of-kind
// output plugs straight in.
#let plain = paths-of-kind(resume-schema, uri-string).fold(
  resume-schema,
  (acc, p) => lens-put(acc, p, str-type),
)
#assert.eq(paths-of-kind(plain, uri-string), ())

// ---- union and `not` members (#164) ----------------------------------------

#let toy = object((
  when: any-of((datetime-string, date-string)),
  place: one-of((str-type, object((city: str-type)))),
  other: not-of(array-of(number-type)),
))
#assert.eq(lens-get(toy, ("other", "not")), array-of(number-type))

// Only the addressed member changes; the rest of the node (exclusive,
// the other members) and of the schema is kept.
#for (at, value, field, node) in (
  (
    ("place", 0),
    content-type,
    "place",
    one-of((
      content-type,
      object((city: str-type)),
    )),
  ),
  (("when", 1), str-type, "when", any-of((datetime-string, str-type))),
  (
    ("place", 1, "city"),
    content-type,
    "place",
    one-of((
      str-type,
      object((city: content-type)),
    )),
  ),
  (("other", "not"), str-type, "other", not-of(str-type)),
) {
  let edited = lens-put(toy, at, value)
  assert.eq(edited.shape.at(field), node)
  for (k, v) in toy.shape {
    if k != field { assert.eq(edited.shape.at(k), v) }
  }
}
#assert.eq(
  lens-over(toy, ("other", "not", "items"), _ => str-type).shape.other,
  not-of(array-of(str-type)),
)

// The strict schema's free-text location member can become content.
#assert.eq(
  kind-at(
    lens-put(
      resume-schema-strict,
      ("work", "items", "location", 0),
      content-type,
    ),
    ("work", "items", "location", 0),
  ),
  "content",
)

// ---- lens-then -------------------------------------------------------------

// Takes either form and returns a lens; composed and direct lenses are
// the same lens, so they read and write alike.
#assert.eq(lens-then(lens(("basics",)), lens(("name",))), name)
#assert.eq(lens-then(("basics",), ("name",)), name)
#assert.eq(lens-then(lens(("basics",)), ("name",)), name)
#assert.eq(lens-then(("basics",), lens(("name",))), name)
#assert.eq(lens-then((), ()), lens(()))
// The identity lens is a unit on either side.
#assert.eq(lens-then(lens(()), name), name)
#assert.eq(lens-then(name, lens(())), name)
// Across an object → array → object boundary.
#let work-highlights = lens-then(lens-then(("work",), ("items",)), (
  "highlights",
))
#assert.eq(work-highlights.lens, ("work", "items", "highlights"))
#assert.eq(lens-get(resume-schema, work-highlights).kind, "array")

// ---- kind-at takes a lens as well as a path ----------------------------------

#assert.eq(kind-at(resume-schema, ("basics", "name")), "string")
#assert.eq(kind-at(resume-schema, name), "string")
