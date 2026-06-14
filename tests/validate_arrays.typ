// _validate on array-of: type check the container, recurse into
// elements with their indexed path.

#import "../internal/validate.typ": _validate
#import "../internal/schema.typ": str-type, array-of

// Valid array of strings.
#assert.eq(_validate(array-of(str-type), ("a", "b", "c"), ("keywords",)), ())

// Not an array.
#let errs = _validate(array-of(str-type), "oops", ("keywords",))
#assert.eq(errs.len(), 1)
#assert(errs.at(0).message.contains("expected array"))

// One bad element among good ones.
#let errs2 = _validate(array-of(str-type), ("ok", 42, "fine"), ("highlights",))
#assert.eq(errs2.len(), 1)
#assert.eq(errs2.at(0).path, ("highlights", 1))
#assert(errs2.at(0).message.contains("expected string"))

// Multiple element errors collected.
#let errs3 = _validate(array-of(str-type), (1, "ok", 2), ("highlights",))
#assert.eq(errs3.len(), 2)
#assert.eq(errs3.at(0).path, ("highlights", 0))
#assert.eq(errs3.at(1).path, ("highlights", 2))
