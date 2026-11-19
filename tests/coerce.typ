// coerce builds the model: markup() wraps a string in Typst content,
// every other leaf passes through, and arrays and objects recurse with
// absent keys left out. It trusts the caller to have validated, so it
// builds what it can for any schema, missing required keys included.

#import "../lib.typ": (
  coerce, markup, boolean, array-of, object, string, number, integer,
)

// Leaves other than content pass through. integer() shares the
// number branch: validation owns the integral gate.
#for (schema, value) in (
  (string(), "hi"),
  (number(), 42),
  (number(), 3.14),
  (integer(), 42),
  (boolean(), true),
  (boolean(), false),
  (array-of(string()), ("a", "b")),
) {
  assert.eq(coerce(schema, value), value)
}

#assert.eq(type(coerce(markup(), "summary text")), content)

// Every element of an array of content wraps.
#let cs = coerce(array-of(markup()), ("one", "two"))
#assert.eq(cs.len(), 2)
#assert.eq(type(cs.at(0)), content)
#assert.eq(type(cs.at(1)), content)

// An object: content fields wrap, the rest pass through.
#let person = object((name: string(), summary: markup(), age: number()))
#let coerced = coerce(person, (name: "Alice", summary: "Hello", age: 30))
#assert.eq(coerced.name, "Alice")
#assert.eq(type(coerced.summary), content)
#assert.eq(coerced.age, 30)

// Missing keys stay absent, required or not.
#assert.eq(coerce(person, (name: "Bob")), (name: "Bob"))
#assert.eq(
  coerce(
    object(
      (title: string(), body: markup()),
      required-keys: ("title", "body"),
    ),
    (title: "hi"),
  ),
  (title: "hi"),
)

// The engine walks any schema: a hand-built extension schema, nested.
#let model = coerce(
  object((
    greeting: markup(),
    rating: number(),
    recipients: array-of(string()),
    details: object((title: string(), bullets: array-of(markup()))),
  )),
  (
    greeting: "Hello",
    rating: 5,
    recipients: ("world", "everyone"),
    details: (title: "Welcome", bullets: ("first point", "second point")),
  ),
)
#assert.eq(type(model.greeting), content)
#assert.eq(model.rating, 5)
#assert.eq(model.recipients, ("world", "everyone"))
#assert.eq(model.details.title, "Welcome")
#assert.eq(type(model.details.bullets.at(0)), content)
