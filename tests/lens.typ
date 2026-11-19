// Lenses: a location in a schema, as `(lens: path)` or the bare path
// array, read with lens-get, replaced with lens-put, mapped with
// lens-over. Each takes the schema first, so
// edits pipe through `.fold`. A segment enters an object field, an
// array's "items", an object's "additionalProperties", a union member
// by index, a `not` member by "not", or a conditional's condition and
// branches by "if", "then" and "else".

#import "../lib.typ": (
  lens-get, lens-put, lens-over, find-paths, validate, object, array-of, markup,
  any-of, one-of, not-of, if-of, schema-from-json-schema, string, number,
)
#import "fixtures/resume.typ": resume-schema, resume-schema-strict

// ---- the lens ----------------------------------------------------------

#let name = (lens: ("basics", "name"))

// ---- lens-get --------------------------------------------------------------

#assert.eq(lens-get(resume-schema, name), string())
#assert.eq(lens-get(resume-schema, ("basics", "name")), string())
#let basics = lens-get(resume-schema, ("basics",))
#assert.eq(basics.kind, "object")
#assert("name" in basics.shape)
// The empty path is the identity.
#assert.eq(lens-get(resume-schema, ()), resume-schema)
#assert.eq(lens-get(resume-schema, (lens: ())), resume-schema)

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
  array-of(string()),
)

// ---- lens-put and lens-over ------------------------------------------------

#let widened = lens-put(resume-schema, name, markup())
#assert.eq(lens-get(widened, name), markup())
#assert.eq(lens-put(resume-schema, ("basics", "name"), markup()), widened)
#assert.eq(lens-over(resume-schema, name, _ => markup()), widened)
#assert.eq(
  lens-over(resume-schema, ("basics", "name"), _ => markup()),
  widened,
)
// Siblings survive untouched, and the original is unchanged.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.label, string())
#assert.eq(lens-get(resume-schema, name), string())

// The identity lens replaces the whole schema, for call sites that take
// a lens generically but sometimes mean "the whole schema".
#assert.eq(lens-put(resume-schema, (), string()), string())
#assert.eq(lens-over(resume-schema, (lens: ()), _ => string()), string())

// A put through an array replaces the element's field and keeps the
// array and object wrappers.
#let rich = lens-put(
  resume-schema,
  ("work", "items", "highlights", "items"),
  markup(),
)
#assert.eq(rich.shape.work.kind, "array")
#assert.eq(rich.shape.work.elem.kind, "object")
#assert.eq(rich.shape.work.elem.shape.highlights, array-of(markup()))

// The extension use case from #26: add `rating` to every language entry,
// a deep edit into languages' items. Only the lensed node changes.
#let language-items = (lens: ("languages", "items"))
#let with-rating = lens-over(
  resume-schema,
  language-items,
  lang => object((..lang.shape, rating: number())),
)
#assert.eq(
  validate(with-rating, (
    languages: ((language: "English", fluency: "native", rating: 5),),
  )),
  (),
)
#assert.eq(lens-get(with-rating, language-items).shape.rating, number())
#assert("rating" not in lens-get(resume-schema, language-items).shape)

// The schema-first order pipes through `.fold`, and find-paths
// output plugs straight in.
#let plain = find-paths(resume-schema, string(format: "uri")).fold(
  resume-schema,
  (acc, p) => lens-put(acc, p, string()),
)
#assert.eq(find-paths(plain, string(format: "uri")), ())

// ---- union, `not` and conditional members (#164, #109) --------------------

#let toy = object((
  when: any-of((string(format: "date-time"), string(format: "date"))),
  place: one-of((string(), object((city: string())))),
  other: not-of(array-of(number())),
  cond: if-of(string(), then: object((b: string())), otherwise: number()),
))
#assert.eq(lens-get(toy, ("other", "not")), array-of(number()))
#assert.eq(lens-get(toy, ("cond", "if")), string())
#assert.eq(lens-get(toy, ("cond", "then", "b")), string())
#assert.eq(lens-get(toy, ("cond", "else")), number())

// Only the addressed member changes; the rest of the node (exclusive,
// the other members) and of the schema is kept.
#for (at, value, field, node) in (
  (
    ("place", 0),
    markup(),
    "place",
    one-of((
      markup(),
      object((city: string())),
    )),
  ),
  (
    ("when", 1),
    string(),
    "when",
    any-of((string(format: "date-time"), string())),
  ),
  (
    ("place", 1, "city"),
    markup(),
    "place",
    one-of((
      string(),
      object((city: markup())),
    )),
  ),
  (("other", "not"), string(), "other", not-of(string())),
  (
    ("cond", "if"),
    markup(),
    "cond",
    if-of(markup(), then: object((b: string())), otherwise: number()),
  ),
  (
    ("cond", "then"),
    number(),
    "cond",
    if-of(string(), then: number(), otherwise: number()),
  ),
  (
    ("cond", "then", "b"),
    markup(),
    "cond",
    if-of(string(), then: object((b: markup())), otherwise: number()),
  ),
  (
    ("cond", "else"),
    string(),
    "cond",
    if-of(string(), then: object((b: string())), otherwise: string()),
  ),
) {
  let edited = lens-put(toy, at, value)
  assert.eq(edited.shape.at(field), node)
  for (k, v) in toy.shape {
    if k != field { assert.eq(edited.shape.at(k), v) }
  }
}
#assert.eq(
  lens-over(toy, ("other", "not", "items"), _ => string()).shape.other,
  not-of(array-of(string())),
)

#assert.eq(
  lens-over(toy, ("cond", "then"), o => object((..o.shape, c: string())))
    .shape
    .cond
    .then,
  object((b: string(), c: string())),
)
// A translated `else` is reached by its JSON Schema name.
#let translated = schema-from-json-schema((
  "if": (type: "string"),
  then: (type: "string", minLength: 1),
  "else": (type: "number"),
))
#assert.eq(lens-get(translated, ("else",)), number())
#assert.eq(
  validate(
    lens-put(translated, ("else",), (
      ..number(),
      minimum: 0,
    )),
    -1,
  ).map(e => e.code),
  ("range",),
)

// The strict schema's free-text location member can become content.
#assert.eq(
  lens-get(
    lens-put(
      resume-schema-strict,
      ("work", "items", "location", 0),
      markup(),
    ),
    ("work", "items", "location", 0),
  ).kind,
  "markup",
)
