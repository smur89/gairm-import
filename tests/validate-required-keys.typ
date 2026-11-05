// The object combinator accepts an optional `required-keys` parameter.
// Default is `()` so v0.1's all-optional behaviour for resume-schema is
// preserved; extension schemas can opt in.

#import "../lib.typ": validate
#import "../internal/validate.typ": _validate
#import "../lib.typ": str-type, object

#let strict-person = object(
  (name: str-type, email: str-type),
  required-keys: ("name",),
)

// Required key present: clean.
#assert.eq(validate((name: "Alice", email: "a@x"), schema: strict-person), ())
#assert.eq(validate((name: "Alice"), schema: strict-person), ())

// Required key absent: one error at the missing path.
#let errs = validate((email: "a@x"), schema: strict-person)
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("name",))
#assert(errs.at(0).message.contains("missing required key"))
#assert(errs.at(0).message.contains("\"name\""))

// Both kinds of error collected — type mismatch on email AND missing required name.
#let errs2 = _validate(strict-person, (email: 42), ("basics",))
#assert.eq(errs2.len(), 2)
#assert.eq(errs2.at(0).path, ("basics", "email"))
#assert(errs2.at(0).message.contains("expected string"))
#assert.eq(errs2.at(1).path, ("basics", "name"))
#assert(errs2.at(1).message.contains("missing required key"))

// Default — no required-keys — preserves all-optional behaviour.
#let lax-person = object((name: str-type, email: str-type))
#assert.eq(validate((:), schema: lax-person), ())
