// _coerce on arrays and objects: recurse, preserve element-level
// coercion (content fields wrap, str fields pass through).

#import "../internal/coerce.typ": _coerce
#import "../internal/kinds.typ": str-type, content-type, number-type, array-of, object

// Array of strings — passes through unchanged.
#assert.eq(_coerce(array-of(str-type), ("a", "b")), ("a", "b"))

// Array of content — every element wraps.
#let cs = _coerce(array-of(content-type), ("one", "two"))
#assert.eq(cs.len(), 2)
#assert.eq(type(cs.at(0)), content)
#assert.eq(type(cs.at(1)), content)

// Object with mixed fields: content wraps, str/number pass through.
#let person = object((name: str-type, summary: content-type, age: number-type))
#let coerced = _coerce(person, (name: "Alice", summary: "Hello", age: 30))
#assert.eq(coerced.name, "Alice")
#assert.eq(type(coerced.summary), content)
#assert.eq(coerced.age, 30)

// Missing keys stay absent from output.
#let partial = _coerce(person, (name: "Bob",))
#assert.eq(partial.keys(), ("name",))
#assert.eq(partial.name, "Bob")
