// enum-of and const-of: membership gates validation, coerce passes a
// member through, and a null member is absorbed by null-as-absent.

#import "../lib.typ": enum-of, const-of, object, validate, coerce

#let fluency = enum-of(("native", "fluent", "intermediate", "beginner"))
#assert.eq(fluency, (
  kind: "enum",
  values: ("native", "fluent", "intermediate", "beginner"),
))
// The values come as separate arguments or as one array; a lone array
// value is wrapped.
#assert.eq(enum-of("a", "b"), enum-of(("a", "b")))
#assert.eq(enum-of("a").values, ("a",))
#assert.eq(enum-of(((1, 2),)).values, ((1, 2),))
#assert.eq(validate(enum-of(((1, 2),)), (1, 2)), ())
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
) {
  let schema = object((f: enum))
  for v in members {
    assert.eq(validate(schema, (f: v)), (), message: repr(v))
    if v != none { assert.eq(coerce(schema, (f: v)), (f: v)) }
  }
  for (v, texts) in misses {
    let errs = validate(schema, (f: v))
    assert.eq(errs.len(), 1, message: repr(v))
    assert.eq(errs.at(0).path, ("f",))
    for t in texts { assert(errs.at(0).message.contains(t), message: t) }
  }
}

// A float meets a decimal as the decimal it is written as, as bounds
// compare them; messages write values as JSON.
#import "../lib.typ": array-of, number
#assert.eq(validate(const-of(decimal("1.5")), 1.5), ())
#assert.eq(validate(enum-of(1.5), decimal("1.5")), ())
#assert.eq(
  validate(array-of(number(), unique-items: true), (decimal("1.5"), 1.5)).map(
    e => e.got,
  ),
  ((0, 1),),
)
#assert.eq(
  validate(enum-of(none, (k: (1, 2))), 5).first().message,
  "expected one of null, {\"k\": [1, 2]}, got 5.",
)
// `expected` names the types a non-null value could have, as a
// nullable union's does.
#assert.eq(validate(enum-of("x", none), 5).first().expected, "string")
// An int past 2^53 is not the float it rounds to, nested or not, as
// unique-items already tells them apart.
#assert.eq(
  validate(enum-of(9007199254740992.0), 9007199254740993).map(e => e.code),
  ("enum",),
)
#assert.eq(
  validate(enum-of(9007199254740993), 9007199254740992.0).map(e => e.code),
  ("enum",),
)
#assert.eq(
  validate(enum-of(((a: 9007199254740992.0),)), (a: 9007199254740993)).map(
    e => e.code,
  ),
  ("enum",),
)
#assert.eq(validate(enum-of(9007199254740992.0), 9007199254740992), ())
