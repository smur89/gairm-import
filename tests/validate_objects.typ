// _validate on object: type-check container, recurse into known keys,
// reject unknown keys with a path-qualified error.

#import "../internal/validate.typ": _validate
#import "../internal/schema.typ": str-type, number-type, object

#let person = object((name: str-type, age: number-type))

// Valid: all known keys, correct types.
#assert.eq(_validate(person, (name: "Alice", age: 30), ()), ())

// Missing optional key: no error (everything is optional).
#assert.eq(_validate(person, (name: "Alice"), ()), ())

// Not an object.
#let errs = _validate(person, "oops", ("basics",))
#assert.eq(errs.len(), 1)
#assert(errs.at(0).message.contains("expected object"))

// Unknown key.
#let errs2 = _validate(person, (name: "Alice", agee: 30), ("basics",))
#assert.eq(errs2.len(), 1)
#assert.eq(errs2.at(0).path, ("basics", "agee"))
#assert(errs2.at(0).message.contains("unknown key"))
#assert(errs2.at(0).message.contains("\"agee\""))
#assert(errs2.at(0).message.contains("Valid keys"))

// Recurse into known keys with wrong types.
#let errs3 = _validate(person, (name: 42, age: "old"), ("basics",))
#assert.eq(errs3.len(), 2)
#assert.eq(errs3.at(0).path, ("basics", "name"))
#assert.eq(errs3.at(1).path, ("basics", "age"))

// Unknown + wrong-type collected together.
#let errs4 = _validate(person, (name: 42, foo: 1), ("basics",))
#assert.eq(errs4.len(), 2)
