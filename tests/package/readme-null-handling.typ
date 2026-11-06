// Mirrors README.md, "Null handling": each row of the table, and the
// example with the result its comment shows. The schemas in the rows
// are ours.
#import "@preview/gairm-import:0.0.0": (
  parse, validate, coerce, object, string, nullable, array-of,
)

#let schema = object(
  (name: string(), nickname: nullable(string())),
  required-keys: ("name", "nickname"),
)
#assert.eq(
  parse((name: "Ada", nickname: none), schema: schema, strict-null: true),
  (name: "Ada", nickname: none),
)

#let codes(data, s, strict) = validate(
  data,
  schema: s,
  strict-null: strict,
).map(e => e.code)
#let req = object((a: string()), required-keys: ("a",))
#let opt = object((a: string()))
#let nul = object((a: nullable(string())))
#let arr = array-of(string())
#let dep = object((a: string(), b: string()), dependent-required: (a: ("b",)))
#let free = object((:), additional: true)

// Required key missing.
#for strict in (false, true) {
  assert.eq(codes((:), req, strict), ("required",))
}
// Key holding null, field not nullable.
#assert.eq(codes((a: none), req, false), ("required",))
#assert.eq(codes((a: none), opt, false), ())
#assert.eq(coerce((a: none), schema: opt), (:))
#assert.eq(codes((a: none), opt, true), ("type",))
#assert(
  validate((a: none), schema: opt, strict-null: true)
    .first()
    .message
    .contains("got null"),
)
// Key holding null, field nullable(X).
#assert.eq(coerce((a: none), schema: nul), (:))
#assert.eq(coerce((a: none), schema: nul, strict-null: true), (a: none))
// Unknown key holding null.
#for strict in (false, true) {
  assert.eq(codes((b: none), opt, strict), ("unknown-key",))
}
// Null array element.
#assert.eq(coerce(("x", none), schema: arr), ("x",))
#assert.eq(codes(("x", none), arr, true), ("type",))
#assert.eq(
  coerce(
    ("x", none),
    schema: array-of(nullable(string())),
    strict-null: true,
  ),
  ("x", none),
)
// Dependent-required trigger holding null.
#assert.eq(codes((a: none), dep, false), ())
#assert.eq(codes((a: none), dep, true), ("type", "dependent"))
// Object whose keys are all null.
#assert.eq(coerce((o: (a: none)), schema: object((o: opt))), (o: (:)))
// Free-form object.
#for strict in (false, true) {
  assert.eq(coerce((a: none), schema: free, strict-null: strict), (a: none))
}
