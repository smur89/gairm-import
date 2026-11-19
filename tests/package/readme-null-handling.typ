// Mirrors README.md, "Null handling": each row of the table, and the
// example with the result its comment shows. The schemas in the rows
// are ours.
#import "@preview/gairm-import:0.0.0": (
  parse, validate, coerce, object, string, nullable, array-of,
)
#import "readme-json-resume.typ": resume-schema
#import "reference-json-resume.typ": resume-schema-strict

#let schema = object(
  (name: string(), nickname: nullable(string())),
  required-keys: ("name", "nickname"),
)
#assert.eq(
  parse(schema, (name: "Ada", nickname: none), strict-null: true),
  (name: "Ada", nickname: none),
)

#let codes(data, s, strict) = validate(s, data, strict-null: strict).map(e => {
  e.code
})
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
#assert.eq(coerce(opt, (a: none)), (:))
#assert.eq(codes((a: none), opt, true), ("type",))
#assert(
  validate(opt, (a: none), strict-null: true)
    .first()
    .message
    .contains("got null"),
)
// Key holding null, field nullable(X).
#assert.eq(coerce(nul, (a: none)), (:))
#assert.eq(coerce(nul, (a: none), strict-null: true), (a: none))
// Unknown key holding null.
#for strict in (false, true) {
  assert.eq(codes((b: none), opt, strict), ("unknown-key",))
}
// Null array element.
#assert.eq(coerce(arr, ("x", none)), ("x",))
#assert.eq(codes(("x", none), arr, true), ("type",))
#assert.eq(
  coerce(array-of(nullable(string())), ("x", none), strict-null: true),
  ("x", none),
)
// Dependent-required trigger holding null.
#assert.eq(codes((a: none), dep, false), ())
#assert.eq(codes((a: none), dep, true), ("type", "dependent"))
// Object whose keys are all null.
#assert.eq(coerce(object((o: opt)), (o: (a: none))), (o: (:)))
// Free-form object.
#for strict in (false, true) {
  assert.eq(coerce(free, (a: none), strict-null: strict), (a: none))
}

// Strict null on a resume schema: a declared field rejects null, the
// free-form `custom` bag keeps it.
#for schema in (resume-schema, resume-schema-strict) {
  assert.eq(
    validate(schema, (basics: (name: none)), strict-null: true).map(
      e => e.code,
    ),
    ("type",),
  )
  assert.eq(
    validate(
      schema,
      (basics: (name: "A", custom: (k: none))),
      strict-null: true,
    ),
    (),
  )
}
