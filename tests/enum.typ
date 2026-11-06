// enum-of and const-of: membership gates validation, coerce passes a
// member through, and a null member is absorbed by null-as-absent.

#import "../lib.typ": enum-of, const-of, object, validate, coerce

#let fluency = enum-of(("native", "fluent", "intermediate", "beginner"))
#assert.eq(fluency, (
  kind: "enum",
  values: ("native", "fluent", "intermediate", "beginner"),
))
// const-of is the singleton enum.
#assert.eq(const-of("v1.0.0"), (kind: "enum", values: ("v1.0.0",)))

// Each row: the enum, members it takes, and values it rejects with one
// error at the field's path, whose message contains the given texts.
#for (enum, members, misses) in (
  (
    fluency,
    ("native", "fluent"),
    (
      ("average", ("expected one of", "\"native\"", "got \"average\"")),
    ),
  ),
  (enum-of((1, 2, 3, 4, 5)), (5,), ((6, ("expected one of", "got 6")),)),
  // Mixed types. `none` is absorbed by validate's null-as-absent: it
  // reads as "key absent", not "matches the none member".
  (
    enum-of(("auto", 0, 100, none)),
    ("auto", 0, 100, none),
    (
      ("max", ()),
    ),
  ),
  (const-of("v1.0.0"), ("v1.0.0",), (("v2.0.0", ("\"v1.0.0\"",)),)),
  // An empty enum rejects everything.
  (enum-of(()), (), (("anything", ("expected one of",)),)),
) {
  let schema = object((f: enum))
  for v in members {
    assert.eq(validate((f: v), schema: schema), (), message: repr(v))
    if v != none { assert.eq(coerce((f: v), schema: schema), (f: v)) }
  }
  for (v, texts) in misses {
    let errs = validate((f: v), schema: schema)
    assert.eq(errs.len(), 1, message: repr(v))
    assert.eq(errs.at(0).path, ("f",))
    for t in texts { assert(errs.at(0).message.contains(t), message: t) }
  }
}
