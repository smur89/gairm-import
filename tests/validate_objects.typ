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

// Unknown key with a close-by valid key: surface a "Did you mean …?"
// hint instead of the full Valid-keys dump. `agee` is one edit from
// `age`, comfortably inside the distance-2 budget.
#let errs2 = _validate(person, (name: "Alice", agee: 30), ("basics",))
#assert.eq(errs2.len(), 1)
#assert.eq(errs2.at(0).path, ("basics", "agee"))
#assert(errs2.at(0).message.contains("unknown key"))
#assert(errs2.at(0).message.contains("\"agee\""))
#assert(errs2.at(0).message.contains("Did you mean \"age\"?"))
#assert(not errs2.at(0).message.contains("Valid keys"))

// Unknown key with no close match: fall back to the full Valid-keys
// list. `xyz` is at distance 3 from every key in the shape.
#let errs2b = _validate(person, (name: "Alice", xyz: 1), ("basics",))
#assert.eq(errs2b.len(), 1)
#assert(errs2b.at(0).message.contains("Valid keys: name, age."))
#assert(not errs2b.at(0).message.contains("Did you mean"))

// Recurse into known keys with wrong types.
#let errs3 = _validate(person, (name: 42, age: "old"), ("basics",))
#assert.eq(errs3.len(), 2)
#assert.eq(errs3.at(0).path, ("basics", "name"))
#assert.eq(errs3.at(1).path, ("basics", "age"))

// Unknown + wrong-type collected together.
#let errs4 = _validate(person, (name: 42, foo: 1), ("basics",))
#assert.eq(errs4.len(), 2)
