// Lenses and introspection reach into unions and `not` (#164): a union
// member's segment is its index, a `not` member's is "not".

#import "../lib.typ": (
  resume-schema, resume-schema-strict, paths-of-kind, kind-at, lens, lens-get,
  lens-put, lens-over, object, array-of, str-type, number-type, content-type,
  date-string, datetime-string, any-of, one-of, not-of,
)

// --- paths-of-kind ---------------------------------------------------

// meta.lastModified is any-of((datetime-string, date-string)) in the
// strict schema: its date member is found alongside the 13 iso8601
// fields.
#let date-paths = paths-of-kind(resume-schema-strict, date-string)
#assert.eq(date-paths.len(), 14)
#assert(("meta", "lastModified", 1) in date-paths)
#assert.eq(
  paths-of-kind(resume-schema-strict, datetime-string),
  (("meta", "lastModified", 0),),
)

// The union node itself is still found.
#assert(("meta", "lastModified") in paths-of-kind(resume-schema-strict, any-of))

// `location` is one-of((str, object)): its free-text member and the
// object member's fields are reachable.
#let str-paths = paths-of-kind(resume-schema, str-type)
#assert(("work", "items", "location", 0) in str-paths)
#assert(("work", "items", "location", 1, "city") in str-paths)

// --- kind-at / lens-get ----------------------------------------------

#assert.eq(
  kind-at(resume-schema-strict, ("meta", "lastModified", 0)),
  "datetime-string",
)
#assert.eq(
  kind-at(resume-schema-strict, ("meta", "lastModified", 1)),
  "date-string",
)
#assert.eq(kind-at(resume-schema, ("work", "items", "location", 1)), "object")

#let toy = object((
  when: any-of((datetime-string, date-string)),
  place: one-of((str-type, object((city: str-type)))),
  other: not-of(array-of(number-type)),
))
#assert.eq(lens-get(lens(("other", "not")), toy), array-of(number-type))
#assert.eq(kind-at(toy, ("other", "not", "items")), "number")
#assert.eq(kind-at(toy, ("place", 1, "city")), "str")

// Every path paths-of-kind returns round-trips through a lens.
#for p in paths-of-kind(toy, str-type) {
  assert.eq(lens-get(lens(p), toy), str-type)
}
#assert.eq(paths-of-kind(toy, str-type), (
  ("place", 0),
  ("place", 1, "city"),
))
#assert.eq(paths-of-kind(toy, number-type), (("other", "not", "items"),))

// --- lens-put / lens-over --------------------------------------------

// Only the addressed member changes; the rest of the node (exclusive,
// the other members) is kept.
#assert.eq(
  lens-put(lens(("place", 0)), toy, content-type).shape.place,
  one-of((content-type, object((city: str-type)))),
)
#assert.eq(
  lens-put(lens(("when", 1)), toy, str-type).shape.when,
  any-of((datetime-string, str-type)),
)
#assert.eq(
  lens-put(lens(("place", 1, "city")), toy, content-type).shape.place,
  one-of((str-type, object((city: content-type)))),
)
#assert.eq(
  lens-put(lens(("other", "not")), toy, str-type).shape.other,
  not-of(str-type),
)
#assert.eq(
  lens-over(lens(("other", "not", "items")), toy, _ => str-type).shape.other,
  not-of(array-of(str-type)),
)
// The rest of the schema is untouched.
#let edited = lens-put(lens(("place", 0)), toy, content-type)
#assert.eq(edited.shape.when, toy.shape.when)
#assert.eq(edited.shape.other, toy.shape.other)

// The strict schema's free-text location member can become content.
#let content-location = lens-put(
  lens(("work", "items", "location", 0)),
  resume-schema-strict,
  content-type,
)
#assert.eq(
  kind-at(content-location, ("work", "items", "location", 0)),
  "content",
)
