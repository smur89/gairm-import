// _coerce on arrays and objects: recurse, preserve element-level
// coercion (content fields wrap, str fields pass through).

#import "../lib.typ": coerce
#import "../lib.typ": str-type, content-type, number-type, array-of, object

// Array of strings — passes through unchanged.
#assert.eq(coerce(("a", "b"), schema: array-of(str-type)), ("a", "b"))

// Array of content — every element wraps.
#let cs = coerce(("one", "two"), schema: array-of(content-type))
#assert.eq(cs.len(), 2)
#assert.eq(type(cs.at(0)), content)
#assert.eq(type(cs.at(1)), content)

// Object with mixed fields: content wraps, str/number pass through.
#let person = object((name: str-type, summary: content-type, age: number-type))
#let coerced = coerce(
  (name: "Alice", summary: "Hello", age: 30),
  schema: person,
)
#assert.eq(coerced.name, "Alice")
#assert.eq(type(coerced.summary), content)
#assert.eq(coerced.age, 30)

// Missing keys stay absent from output.
#let partial = coerce((name: "Bob"), schema: person)
#assert.eq(partial.keys(), ("name",))
#assert.eq(partial.name, "Bob")
