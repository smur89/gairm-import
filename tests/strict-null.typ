// strict-null (#84): one assertion per row of the semantics table, in
// both modes, through the public API. Default mode (null-as-absent) is
// unchanged; `strict-null: true` makes null an ordinary value that a
// schema accepts (null-type, nullable(X)) or rejects with `type`.

#import "../lib.typ": (
  validate, coerce, parse, str-type, null-type, array-of, object, nullable,
  any-of, one-of, enum-of, describe-schema,
)

#let codes(errs) = errs.map(e => (e.path, e.code))

// --- key missing, required: `required` in both modes -----------------

#let req = object((name: str-type), required-keys: ("name",))
#assert.eq(codes(validate((:), schema: req)), ((("name",), "required"),))
#assert.eq(
  codes(validate((:), schema: req, strict-null: true)),
  ((("name",), "required"),),
)

// --- null, required, not nullable ------------------------------------

#assert.eq(codes(validate((name: none), schema: req)), (
  (("name",), "required"),
))
#let strict-req = validate((name: none), schema: req, strict-null: true)
#assert.eq(codes(strict-req), ((("name",), "type"),))
#assert.eq(strict-req.at(0).message, "expected string, got null.")
#assert.eq(strict-req.at(0).got, "null")

// --- null, optional, not nullable ------------------------------------

#let opt = object((name: str-type, age: str-type))
#assert.eq(validate((name: none), schema: opt), ())
#assert.eq(coerce((name: none, age: "3"), schema: opt), (age: "3"))
#assert.eq(parse((name: none, age: "3"), schema: opt), (age: "3"))
#assert.eq(
  codes(validate((name: none), schema: opt, strict-null: true)),
  ((("name",), "type"),),
)

// --- null, nullable(X): dropped by default, kept in strict mode ------

#let nul = object((name: nullable(str-type)), required-keys: ("name",))
#assert.eq(codes(validate((name: none), schema: nul)), (
  (("name",), "required"),
))
#let nul-opt = object((name: nullable(str-type)))
#assert.eq(validate((name: none), schema: nul-opt), ())
#assert.eq(coerce((name: none), schema: nul-opt), (:))
#assert.eq(validate((name: none), schema: nul, strict-null: true), ())
#assert.eq(coerce((name: none), schema: nul, strict-null: true), (name: none))
#assert.eq(parse((name: none), schema: nul, strict-null: true), (name: none))
#assert.eq(
  parse((name: "a"), schema: nul, strict-null: true),
  (name: "a"),
)

// --- null array element, elem not nullable ---------------------------

#let strs = array-of(str-type)
#assert.eq(validate(("a", none), schema: strs), ())
#assert.eq(coerce(("a", none), schema: strs), ("a",))
#assert.eq(
  codes(validate(("a", none), schema: strs, strict-null: true)),
  (((1,), "type"),),
)

// --- null array element, elem nullable(X): counts for the rows -------

#let nstrs = (..array-of(nullable(str-type)), min-items: 2, unique-items: true)
#assert.eq(codes(validate(("a", none), schema: nstrs)), (((), "items"),))
#assert.eq(coerce(("a", none), schema: nstrs), ("a",))
#assert.eq(validate(("a", none), schema: nstrs, strict-null: true), ())
#assert.eq(
  coerce(("a", none), schema: nstrs, strict-null: true),
  ("a", none),
)
#assert.eq(validate((none, "a", "b", none), schema: nstrs), ())
#let dup = validate((none, "a", "b", none), schema: nstrs, strict-null: true)
#assert.eq(codes(dup), (((), "unique"),))
#assert.eq(dup.at(0).got, (0, 3))

// --- dependent trigger with null -------------------------------------

#let dep = object(
  (a: nullable(str-type), b: str-type),
  dependent-required: (a: ("b",)),
)
#assert.eq(validate((a: none), schema: dep), ())
#assert.eq(
  codes(validate((a: none), schema: dep, strict-null: true)),
  (((), "dependent"),),
)

// --- null root: the input handler is mode-independent ----------------
// (tests/panics/strict-null-root.typ checks the panic text.)

// --- free-form objects pass through as given -------------------------

#let bag = object((:), additional: true)
#let free = (a: none, b: (c: none))
#assert.eq(validate(free, schema: bag), ())
#assert.eq(coerce(free, schema: bag), free)
#assert.eq(validate(free, schema: bag, strict-null: true), ())
#assert.eq(coerce(free, schema: bag, strict-null: true), free)

// --- the union rule: null-type never competes for a non-null value ---

#for strict in (false, true) {
  let plain = validate((name: 1), schema: object((name: str-type)))
  let wrapped = validate(
    (name: 1),
    schema: object((name: nullable(str-type))),
    strict-null: strict,
  )
  assert.eq(wrapped, plain)
  assert.eq(wrapped.at(0).message, "expected string, got integer.")
  // Several non-null members: the summary names only them.
  let multi = validate(
    true,
    schema: any-of((str-type, enum-of((1,)), null-type)),
    strict-null: strict,
  )
  assert.eq(
    multi,
    validate(true, schema: any-of((str-type, enum-of((1,))))),
  )
}

// In strict mode a non-nullable union sees the null and rejects it.
#let u = validate(
  (f: none),
  schema: object((f: any-of((str-type, enum-of((1,)))))),
  strict-null: true,
)
#assert.eq(codes(u), ((("f",), "type"),))
#assert.eq(u.at(0).got, "null")
// A union of null-type alone still judges a non-null value against it.
#assert.eq(
  codes(validate(1, schema: any-of((null-type,)), strict-null: true)),
  (((), "type"),),
)

// null-type: accepts null in strict mode, rejects anything else in both.
#assert.eq(
  validate((f: none), schema: object((f: null-type)), strict-null: true),
  (),
)
#assert.eq(
  validate(1, schema: null-type, strict-null: true).at(0).message,
  "expected null, got integer.",
)

// one-of over a nullable: a null matches only null-type.
#assert.eq(
  validate(
    (f: none),
    schema: object((f: one-of((str-type, null-type)))),
    strict-null: true,
  ),
  (),
)

// --- nullable() construction and describe-schema ---------------------

#assert.eq(nullable(str-type), any-of((str-type, null-type)))
#assert.eq(describe-schema(nullable(str-type)), "str?")
#assert.eq(
  describe-schema(object((
    a: nullable((..str-type, min-length: 1)),
    b: nullable(object((c: str-type))),
    d: nullable(array-of(str-type)),
    e: array-of(nullable(str-type)),
  ))),
  "a     str? (min-length 1)\nb?:\n  c  str\nd?[]  str\ne[]   str?",
)
// The mark follows a leaf's kind, a header, or the label of a node
// drawn by its label alone, so a nullable array and an array of
// nullables differ.
#assert.eq(
  describe-schema(object((
    d: nullable(array-of(object((c: str-type)))),
    e: array-of(nullable(object((c: str-type)))),
    u: nullable(one-of((str-type, enum-of((1,))))),
  ))),
  "d?[]:\n  c  str\ne[]?:\n  c  str\nu  one of?:\n  [0]  str\n  [1]  enum (1)",
)
#assert.eq(describe-schema(nullable(array-of(str-type))), "?[] str")
#assert.eq(describe-schema(nullable(object((c: str-type)))), "?:\n  c  str")
// Only the exact (X, null-type) any-of pair draws as X?.
#assert.eq(
  describe-schema(any-of((null-type, str-type))),
  "any of:\n  [0]  null\n  [1]  str",
)
#assert.eq(
  describe-schema(one-of((str-type, null-type))),
  "one of:\n  [0]  str\n  [1]  null",
)

// README "Strict null" example.
#assert.eq(
  parse(
    (name: "Ada", nickname: none),
    schema: object(
      (name: str-type, nickname: nullable(str-type)),
      required-keys: ("name", "nickname"),
    ),
    strict-null: true,
  ),
  (name: "Ada", nickname: none),
)
