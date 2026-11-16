// coerce builds the model: content-type wraps a string in Typst content,
// every other leaf passes through, and arrays and objects recurse with
// absent keys left out. It trusts the caller to have validated, so it
// builds what it can for any schema, missing required keys included.

#import "../lib.typ": (
  coerce, content-type, bool-type, array-of, object, string, number, integer,
)

// Leaves other than content pass through. integer() shares the
// number branch: validation owns the integral gate.
#for (schema, value) in (
  (string(), "hi"),
  (number(), 42),
  (number(), 3.14),
  (integer(), 42),
  (bool-type, true),
  (bool-type, false),
  (array-of(string()), ("a", "b")),
) {
  assert.eq(coerce(value, schema: schema), value)
}

#assert.eq(type(coerce("summary text", schema: content-type)), content)

// Every element of an array of content wraps.
#let cs = coerce(("one", "two"), schema: array-of(content-type))
#assert.eq(cs.len(), 2)
#assert.eq(type(cs.at(0)), content)
#assert.eq(type(cs.at(1)), content)

// An object: content fields wrap, the rest pass through.
#let person = object((name: string(), summary: content-type, age: number()))
#let coerced = coerce(
  (name: "Alice", summary: "Hello", age: 30),
  schema: person,
)
#assert.eq(coerced.name, "Alice")
#assert.eq(type(coerced.summary), content)
#assert.eq(coerced.age, 30)

// Missing keys stay absent, required or not.
#assert.eq(coerce((name: "Bob"), schema: person), (name: "Bob"))
#assert.eq(
  coerce(
    (title: "hi"),
    schema: object(
      (title: string(), body: content-type),
      required-keys: ("title", "body"),
    ),
  ),
  (title: "hi"),
)

// The engine walks any schema: a hand-built extension schema, nested.
#let model = coerce(
  (
    greeting: "Hello",
    rating: 5,
    recipients: ("world", "everyone"),
    details: (title: "Welcome", bullets: ("first point", "second point")),
  ),
  schema: object((
    greeting: content-type,
    rating: number(),
    recipients: array-of(string()),
    details: object((title: string(), bullets: array-of(content-type))),
  )),
)
#assert.eq(type(model.greeting), content)
#assert.eq(model.rating, 5)
#assert.eq(model.recipients, ("world", "everyone"))
#assert.eq(model.details.title, "Welcome")
#assert.eq(type(model.details.bullets.at(0)), content)
