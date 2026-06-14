// _validate dispatches on schema.kind for primitive types.

#import "../internal/validate.typ": _validate
#import "../internal/schema.typ": str-type, content-type, number-type

// Valid: empty error list.
#assert.eq(_validate(str-type, "hi", ("name",)), ())
#assert.eq(_validate(content-type, "summary text", ("summary",)), ())
#assert.eq(_validate(number-type, 42, ("age",)), ())
#assert.eq(_validate(number-type, 3.14, ("rating",)), ())

// Invalid: wrong type yields one error at the given path.
#let errs = _validate(str-type, 42, ("basics", "email"))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics", "email"))
#assert(errs.at(0).message.contains("expected string"))

#let errs2 = _validate(number-type, "nope", ("rating",))
#assert.eq(errs2.len(), 1)
#assert(errs2.at(0).message.contains("expected number"))
