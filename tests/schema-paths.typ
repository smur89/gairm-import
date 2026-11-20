// A schema path, an array of segments, read with schema-get, replaced
// with schema-put, mapped with schema-update. Each takes the schema
// first, so edits pipe through `.fold`. A segment enters an object field, an
// array's "items", an object's "additionalProperties", a union member
// by index, a `not` member by "not", or a conditional's condition and
// branches by "if", "then" and "else".

#import "../lib.typ": (
  schema-get, schema-put, schema-update, find-paths, validate, object, array-of,
  markup, any-of, one-of, not-of, if-of, schema-from-json-schema, string,
  number,
)
#import "fixtures/resume.typ": resume-schema, resume-schema-strict

// ---- the path ----------------------------------------------------------

#let name = ("basics", "name")

// ---- schema-get --------------------------------------------------------------

#assert.eq(schema-get(resume-schema, name), string())
#assert.eq(schema-get(resume-schema, ("basics", "name")), string())
#let basics = schema-get(resume-schema, ("basics",))
#assert.eq(basics.kind, "object")
#assert("name" in basics.shape)
// The empty path is the identity.
#assert.eq(schema-get(resume-schema, ()), resume-schema)

// "items" enters an array's elements: ("work", "items", "highlights")
// is the highlights field of each work entry.
#assert.eq(schema-get(resume-schema, ("work",)).kind, "array")
#let work-item = schema-get(resume-schema, ("work", "items"))
#assert.eq(work-item.kind, "object")
#assert("position" in work-item.shape)
#assert("highlights" in work-item.shape)
// The faithful schema keeps highlights as plain str; the strict variant
// is what makes them content. The path just walks.
#assert.eq(
  schema-get(resume-schema, ("work", "items", "highlights")),
  array-of(string()),
)

// ---- schema-put and schema-update ------------------------------------------------

#let widened = schema-put(resume-schema, name, markup())
#assert.eq(schema-get(widened, name), markup())
#assert.eq(schema-put(resume-schema, ("basics", "name"), markup()), widened)
#assert.eq(schema-update(resume-schema, name, _ => markup()), widened)
#assert.eq(
  schema-update(resume-schema, ("basics", "name"), _ => markup()),
  widened,
)
// Siblings survive untouched, and the original is unchanged.
#assert.eq(widened.shape.work, resume-schema.shape.work)
#assert.eq(widened.shape.basics.shape.label, string())
#assert.eq(schema-get(resume-schema, name), string())

// The empty path replaces the whole schema, for call sites that take
// a path generically but sometimes mean "the whole schema".
#assert.eq(schema-put(resume-schema, (), string()), string())
#assert.eq(schema-update(resume-schema, (), _ => string()), string())

// A put through an array replaces the element's field and keeps the
// array and object wrappers.
#let rich = schema-put(
  resume-schema,
  ("work", "items", "highlights", "items"),
  markup(),
)
#assert.eq(rich.shape.work.kind, "array")
#assert.eq(rich.shape.work.elem.kind, "object")
#assert.eq(rich.shape.work.elem.shape.highlights, array-of(markup()))

// The extension use case from #26: add `rating` to every language entry,
// a deep edit into languages' items. Only the node at the path changes.
#let language-items = ("languages", "items")
#let with-rating = schema-update(
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
#assert.eq(schema-get(with-rating, language-items).shape.rating, number())
#assert("rating" not in schema-get(resume-schema, language-items).shape)

// The schema-first order pipes through `.fold`, and find-paths
// output plugs straight in.
#let plain = find-paths(resume-schema, string(format: "uri")).fold(
  resume-schema,
  (acc, p) => schema-put(acc, p, string()),
)
#assert.eq(find-paths(plain, string(format: "uri")), ())

// ---- union, `not` and conditional members (#164, #109) --------------------

#let toy = object((
  when: any-of((string(format: "date-time"), string(format: "date"))),
  place: one-of((string(), object((city: string())))),
  other: not-of(array-of(number())),
  cond: if-of(string(), then: object((b: string())), otherwise: number()),
))
#assert.eq(schema-get(toy, ("other", "not")), array-of(number()))
#assert.eq(schema-get(toy, ("cond", "if")), string())
#assert.eq(schema-get(toy, ("cond", "then", "b")), string())
#assert.eq(schema-get(toy, ("cond", "else")), number())

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
  let edited = schema-put(toy, at, value)
  assert.eq(edited.shape.at(field), node)
  for (k, v) in toy.shape {
    if k != field { assert.eq(edited.shape.at(k), v) }
  }
}
#assert.eq(
  schema-update(toy, ("other", "not", "items"), _ => string()).shape.other,
  not-of(array-of(string())),
)

#assert.eq(
  schema-update(toy, ("cond", "then"), o => object((..o.shape, c: string())))
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
#assert.eq(schema-get(translated, ("else",)), number())
#assert.eq(
  validate(
    schema-put(translated, ("else",), (
      ..number(),
      minimum: 0,
    )),
    -1,
  ).map(e => e.code),
  ("range",),
)

// The strict schema's free-text location member can become content.
#assert.eq(
  schema-get(
    schema-put(
      resume-schema-strict,
      ("work", "items", "location", 0),
      markup(),
    ),
    ("work", "items", "location", 0),
  ).kind,
  "markup",
)

// A write into a set additional schema replaces it, and one into a field
// literally named "additionalProperties" replaces the field, on a closed
// object too: only an additional schema that is not set refuses a write.
#assert.eq(
  schema-put(
    object((:), additional: string()),
    ("additionalProperties",),
    number(),
  ),
  object((:), additional: number()),
)
#assert.eq(
  schema-put(
    object(("additionalProperties": string())),
    ("additionalProperties",),
    number(),
  ),
  object(("additionalProperties": number())),
)
