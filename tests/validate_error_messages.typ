// Pin the rendered tail of type-mismatch messages so README samples
// and runtime output stay in lockstep. Without these asserts a Typst
// upgrade that changes type reprs (or a refactor that drops the
// friendly _type-name-of mapping) would silently diverge.

#import "../internal/validate.typ": _validate
#import "../internal/schema.typ": str-type, number-type, array-of, object

#let one(schema, value, path) = {
  let errs = _validate(schema, value, path)
  assert.eq(errs.len(), 1)
  errs.at(0).message
}

#assert.eq(one(str-type, 42, ("email",)), "expected string, got integer.")
#assert.eq(one(str-type, 3.14, ("rating",)), "expected string, got number.")
#assert.eq(one(str-type, true, ("flag",)), "expected string, got boolean.")
#assert.eq(one(str-type, none, ("missing",)), "expected string, got null.")
#assert.eq(one(number-type, "nope", ("age",)), "expected number, got string.")
#assert.eq(one(array-of(str-type), "x", ("k",)), "expected array, got string.")
#assert.eq(one(object((name: str-type)), "x", ("b",)), "expected object, got string.")
