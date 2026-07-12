// Composition keywords (allOf / anyOf / oneOf / not) — #108.
//
// allOf is translator-only (object-merge subset, no new engine kind);
// anyOf / oneOf translate to the union kind, not to the not kind —
// both validated in _validate, coerced via first-matching-member.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, str-type, content-type,
  number-type, integer-type, bool-type, object, array-of, enum-of, any-of,
  one-of, not-of,
)

// --- translator: allOf (object-merge subset) -------------------------

// Shapes union, required-keys union.
#let merged = schema-from-json-schema((
  allOf: (
    (
      type: "object",
      properties: (name: (type: "string")),
      required: ("name",),
    ),
    (type: "object", properties: (age: (type: "integer")), required: ("age",)),
  ),
))
#assert.eq(merged.kind, "object")
#assert.eq(merged.shape.name, str-type)
#assert.eq(merged.shape.age, integer-type)
#assert.eq(merged.required-keys, ("name", "age"))

// Single-member allOf is the identity.
#let single = schema-from-json-schema((
  allOf: ((type: "object", properties: (a: (type: "string"))),),
))
#assert.eq(single.shape.a, str-type)

// Duplicate keys with EQUAL sub-schemas merge cleanly.
#let dup = schema-from-json-schema((
  allOf: (
    (type: "object", properties: (a: (type: "string"))),
    (type: "object", properties: (a: (type: "string"), b: (type: "number"))),
  ),
))
#assert.eq(dup.shape.a, str-type)
#assert.eq(dup.shape.b, number-type)

// $refs inside members resolve against the document root.
#let with-ref = schema-from-json-schema((
  definitions: (base: (type: "object", properties: (id: (type: "string")))),
  allOf: (
    ("$ref": "#/definitions/base"),
    (type: "object", properties: (extra: (type: "number"))),
  ),
))
#assert.eq(with-ref.shape.id, str-type)
#assert.eq(with-ref.shape.extra, number-type)

// additionalProperties must agree across ALL members (an undeclared
// member counts as closed) — a closed member combined with an open one
// bails rather than silently producing an open merge that would accept
// keys the closed member rejects.
#let with-ap = schema-from-json-schema((
  allOf: (
    (
      type: "object",
      properties: (a: (type: "string")),
      additionalProperties: true,
    ),
    (
      type: "object",
      properties: (b: (type: "number")),
      additionalProperties: true,
    ),
  ),
))
#assert.eq(with-ap.additional, true)

// Annotation-only siblings (title, description, …) are tolerated.
#let annotated = schema-from-json-schema((
  title: "combined",
  description: "docs only",
  allOf: ((type: "object", properties: (a: (type: "string"))),),
))
#assert.eq(annotated.shape.a, str-type)

// --- translator: anyOf / oneOf / not ---------------------------------

#assert.eq(
  schema-from-json-schema((anyOf: ((type: "string"), (type: "number")))),
  any-of((str-type, number-type)),
)
#assert.eq(
  schema-from-json-schema((oneOf: ((type: "string"), (type: "boolean")))),
  one-of((str-type, bool-type)),
)
#assert.eq(
  schema-from-json-schema(("not": (type: "string"))),
  not-of(str-type),
)

// Nested composition round-trips.
#assert.eq(
  schema-from-json-schema((
    anyOf: ((type: "string"), (oneOf: ((type: "number"), (type: "boolean")))),
  )),
  any-of((str-type, one-of((number-type, bool-type)))),
)

// --- validator: union (any-of) ----------------------------------------

#let str-or-num = any-of((str-type, number-type))
#assert.eq(validate("hi", schema: str-or-num), ())
#assert.eq(validate(42, schema: str-or-num), ())

#let no-match = validate(true, schema: str-or-num)
#assert.eq(no-match.len(), 1)
#assert.eq(no-match.at(0).path, ())
#assert(no-match.at(0).message.contains("none matched"))
#assert(no-match.at(0).message.contains("str | number"))

// Union nested inside an object keeps path-qualified reporting.
#let holder = object((value: any-of((str-type, array-of(number-type)))))
#assert.eq(validate((value: (1, 2)), schema: holder), ())
#assert.eq(validate((value: "text"), schema: holder), ())
#let nested-err = validate((value: true), schema: holder)
#assert.eq(nested-err.len(), 1)
#assert.eq(nested-err.at(0).path, ("value",))

// Null at a union position is "key absent", like every other kind.
#assert.eq(validate((value: none), schema: holder), ())

// --- validator: union (one-of, exactly-one) ---------------------------

#let exclusive = one-of((number-type, enum-of((1, 2))))
// 3 matches only number-type — exactly one.
#assert.eq(validate(3, schema: exclusive), ())
// 1 matches both members — exclusivity violated.
#let multi = validate(1, schema: exclusive)
#assert.eq(multi.len(), 1)
#assert(multi.at(0).message.contains("exactly one"))
#assert(multi.at(0).message.contains("2 matched"))

// --- validator: not ----------------------------------------------------

#let not-str = not-of(str-type)
#assert.eq(validate(42, schema: not-str), ())
#assert.eq(validate((a: 1), schema: not-str), ())
#let negated = validate("nope", schema: not-str)
#assert.eq(negated.len(), 1)
#assert(negated.at(0).message.contains("not matching"))

// --- coerce ------------------------------------------------------------

// Union delegates to the first matching member — content wraps, the
// rest pass through untouched.
#let rich-or-num = any-of((content-type, number-type))
#assert.eq(type(coerce("hello", schema: rich-or-num)), content)
#assert.eq(coerce(7, schema: rich-or-num), 7)

// Inside a document, union-typed keys behave like any other key.
#let doc-schema = object((x: any-of((str-type, number-type))))
#assert.eq(coerce((x: 5), schema: doc-schema).x, 5)
#assert.eq(coerce((x: "s"), schema: doc-schema).x, "s")

// `not` has no shape to coerce toward — value passes through verbatim.
#assert.eq(coerce(42, schema: not-of(str-type)), 42)
#assert.eq(coerce((a: 1), schema: not-of(str-type)), (a: 1))

// --- strict stripping recurses into union members ----------------------

#import "../internal/schema.typ": _strip-permissive-additional

// `additional: true` inside a union member is stripped like anywhere
// else — a member is a positive matcher for the document, so stripping
// tightens it, consistent with the strict variant's promise.
#let permissive-union = any-of((
  object((x: str-type), additional: true),
  str-type,
))
#let stripped = _strip-permissive-additional(permissive-union)
#assert("additional" not in stripped.members.at(0))
#assert.eq(stripped.members.at(1), str-type)

// Typed extras inside union members are kept, same as at top level.
#let typed-union = any-of((object((:), additional: number-type),))
#assert.eq(
  _strip-permissive-additional(typed-union).members.at(0).additional,
  number-type,
)

// Negation context inverts strip semantics — a stricter negated
// matcher rejects less, so `not` members stay exactly as authored.
#let negated = not-of(object((x: str-type), additional: true))
#assert.eq(_strip-permissive-additional(negated), negated)
