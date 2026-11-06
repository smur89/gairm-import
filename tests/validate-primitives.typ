// _validate dispatches on schema.kind for primitive types.

#import "../internal/engine.typ": _validate
#import "../internal/core/ctx.typ": _ctx
#import "../lib.typ": str-type, content-type, number-type, integer-type

// Valid: empty error list.
#assert.eq(_validate(str-type, "hi", _ctx(path: ("name",))), ())
#assert.eq(
  _validate(content-type, "summary text", _ctx(path: ("summary",))),
  (),
)
#assert.eq(_validate(number-type, 42, _ctx(path: ("age",))), ())
#assert.eq(_validate(number-type, 3.14, _ctx(path: ("rating",))), ())

// Invalid: wrong type yields one error at the given path.
#let errs = _validate(str-type, 42, _ctx(path: ("basics", "email")))
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("basics", "email"))
#assert(errs.at(0).message.contains("expected string"))

#let errs2 = _validate(number-type, "nope", _ctx(path: ("rating",)))
#assert.eq(errs2.len(), 1)
#assert(errs2.at(0).message.contains("expected number"))

// integer-type: draft-7 semantics — any number with a zero fractional
// part, so float 2.0 passes and 1.5 fails.
#assert.eq(_validate(integer-type, 42, _ctx(path: ("age",))), ())
#assert.eq(_validate(integer-type, 2.0, _ctx(path: ("age",))), ())
#let int-errs = _validate(integer-type, 1.5, _ctx(path: ("age",)))
#assert.eq(int-errs.len(), 1)
#assert.eq(int-errs.at(0).path, ("age",))
#assert(int-errs.at(0).message.contains("expected an integer"))
// Non-numbers still fail the number gate first.
#let int-type-errs = _validate(integer-type, "nope", _ctx(path: ("age",)))
#assert.eq(int-type-errs.len(), 1)
#assert(int-type-errs.at(0).message.contains("expected number"))
