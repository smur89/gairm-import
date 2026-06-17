// `additionalProperties` translation + the `map(value-schema)`
// combinator — #77.

#import "../lib.typ": (
  validate, coerce,
  schema-from-json-schema,
  object, map, str-type, number-type, email-string, array-of,
  lens, lens-get, lens-put, paths-of-kind, describe-schema,
)

// --- map() convenience ----------------------------------------------

#let str-map = map(str-type)
#assert.eq(str-map.kind, "object")
#assert.eq(str-map.shape, (:))
#assert.eq(str-map.additional, str-type)

// All-strings map: arbitrary keys, every value validated.
#assert.eq(validate((en: "English", fr: "Français"), schema: str-map), ())

#let map-errs = validate((en: "English", fr: 42), schema: str-map)
#assert.eq(map-errs.len(), 1)
#assert.eq(map-errs.at(0).path, ("fr",))
#assert(map-errs.at(0).message.contains("expected string"))

// Coerce passes through every key, dropping nulls.
#assert.eq(
  coerce((a: "x", b: "y", c: none), schema: str-map),
  (a: "x", b: "y"),
)

// --- object with both properties and additional ---------------------

#let mixed = object(
  (name: str-type),
  required-keys: ("name",),
  additional: number-type,
)

// Declared key validated per properties; extras per `additional`.
#assert.eq(validate((name: "Ada", year: 1815, age: 200), schema: mixed), ())

// Wrong type on a declared key still errors via the property schema.
#let mixed-err = validate((name: 1, year: 1815), schema: mixed)
#assert.eq(mixed-err.len(), 1)
#assert.eq(mixed-err.at(0).path, ("name",))

// Wrong type on an extra errors via `additional`.
#let extra-err = validate((name: "Ada", year: "1815"), schema: mixed)
#assert.eq(extra-err.len(), 1)
#assert.eq(extra-err.at(0).path, ("year",))
#assert(extra-err.at(0).message.contains("expected number"))

// --- additional: true (pass-through) --------------------------------

#let permissive = object((name: str-type), additional: true)
// Any extra accepted without validation.
#assert.eq(validate((name: "Ada", anything: ((nested: ("array",))), other: 42), schema: permissive), ())

// Coerce preserves extras verbatim — no recursion into them.
#assert.eq(
  coerce((name: "Ada", whatever: (a: 1, b: 2)), schema: permissive),
  (name: "Ada", whatever: (a: 1, b: 2)),
)

// --- strict path unchanged (no `additional`) ------------------------

#let strict = object((name: str-type))
#let strict-err = validate((name: "Ada", year: 1815), schema: strict)
#assert.eq(strict-err.len(), 1)
#assert(strict-err.at(0).message.contains("unknown key"))

// --- translator: each additionalProperties form ---------------------

// (a) properties, no additionalProperties → strict (default)
#let t-no-ap = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
))
#assert.eq(t-no-ap.kind, "object")
#assert("additional" not in t-no-ap)

// (b) properties + additionalProperties: false → strict (same shape)
#let t-ap-false = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: false,
))
#assert("additional" not in t-ap-false)

// (c) properties + additionalProperties: true → permissive
#let t-ap-true = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: true,
))
#assert.eq(t-ap-true.additional, true)

// (d) properties + additionalProperties: <schema> → typed extras
#let t-ap-schema = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: (type: "number"),
))
#assert.eq(t-ap-schema.additional, number-type)

// (e) no properties + additionalProperties: <schema> → pure map
#let t-pure-map = schema-from-json-schema((
  type: "object",
  additionalProperties: (type: "string"),
))
#assert.eq(t-pure-map, map(str-type))

// (f) no properties, no additionalProperties → still bails (unchanged)
#let bail-src = read("../internal/json-schema.typ")
#assert(bail-src.contains("open object schemas"))
#assert(bail-src.contains("must be a schema, true, or false"))

// --- constructor: `additional` validated up front -------------------
//
// `object()` rejects anything that isn't `none`, `true`, or a schema
// dict, so a hand-built schema with e.g. `additional: false` fails
// at construction instead of crashing inside _validate when `.kind`
// is read.
#let kinds-src = read("../internal/kinds.typ")
#assert(kinds-src.contains("additional must be none, false, true, or a schema dict"))

// `additional` + required-key-not-in-shape is now allowed — the
// extra key gets validated by `additional`, so the construction-time
// subset check is skipped when an additional schema is present.
#let open-required = object(
  (:),
  required-keys: ("id",),
  additional: str-type,
)
#assert.eq(open-required.required-keys, ("id",))
// And the runtime still flags it missing if absent…
#let missing = validate((:), schema: open-required)
#assert.eq(missing.len(), 1)
#assert(missing.at(0).message.contains("missing required key \"id\""))
// …and validates the value against `additional` when present.
#assert.eq(validate((id: "abc"), schema: open-required), ())
#let wrong-type = validate((id: 1), schema: open-required)
#assert.eq(wrong-type.len(), 1)
#assert(wrong-type.at(0).message.contains("expected string"))

// --- error path uses the actual key, not "items" --------------------
//
// A pure map of objects: error inside one entry surfaces the real key.
#let book-map = map(object((title: str-type), required-keys: ("title",)))
#let bad-books = validate(
  (
    one: (title: "Ulysses"),
    two: (title: 42),
  ),
  schema: book-map,
)
#assert.eq(bad-books.len(), 1)
#assert.eq(bad-books.at(0).path, ("two", "title"))

// --- constructor: `additional: false` ≡ `none` -----------------------
//
// JSON Schema's `additionalProperties: false` and our `additional: none`
// are semantically identical. The constructor accepts both so callers
// fluent in JSON Schema vocabulary don't trip on the assert.
#let strict-via-false = object((name: str-type), additional: false)
#assert("additional" not in strict-via-false)
#let strict-via-none = object((name: str-type))
#assert.eq(strict-via-false, strict-via-none)

// --- map(v, required-keys: …) symmetry with object ------------------
#let required-map = map(str-type, required-keys: ("id",))
#assert.eq(required-map.required-keys, ("id",))
#assert.eq(required-map.additional, str-type)
#assert.eq(validate((id: "abc", other: "ok"), schema: required-map), ())
#let missing-id = validate((other: "ok"), schema: required-map)
#assert.eq(missing-id.len(), 1)
#assert(missing-id.at(0).message.contains("missing required key \"id\""))

// --- all-none extras collapse the object to none --------------------
//
// Symmetry with the leaf-null policy: an object whose every key
// coerced to none collapses to none itself. With `additional`, the
// open keys participate in that collapse.
#assert.eq(coerce((a: none, b: none), schema: map(str-type)), none)
#assert.eq(
  coerce((id: "x", a: none, b: none), schema: map(str-type, required-keys: ("id",))),
  (id: "x"),
)

// --- introspection: `paths-of-kind` descends into `additional` -----
//
// Path segment is `"additionalProperties"` (matching the JSON Schema
// keyword name, same convention as `"items"` for arrays). The
// emitted path round-trips through `lens-get`.
#let tags-schema = object(
  (name: str-type, tags: map(str-type)),
  required-keys: ("name",),
)
#assert.eq(
  paths-of-kind(tags-schema, "str"),
  (("name",), ("tags", "additionalProperties")),
)
// Round-trip: the segment is a real lens path.
#assert.eq(lens-get(lens(("tags", "additionalProperties")), tags-schema), str-type)

// Nested `additional` inside `additional` works too.
#let nested-maps = map(map(number-type))
#assert.eq(
  paths-of-kind(nested-maps, "number"),
  (("additionalProperties", "additionalProperties"),),
)

// --- lens: `"additionalProperties"` writes back into `additional` --
#let updated = lens-put(lens(("tags", "additionalProperties")), tags-schema, number-type)
#assert.eq(updated.shape.tags.additional, number-type)
// Shape outside the lensed path is untouched.
#assert.eq(updated.shape.name, str-type)

// Trying to lens through `additionalProperties` when `additional` is
// true (no schema) bails with a grep-able message.
#let lens-src = read("../internal/lens.typ")
#assert(lens-src.contains("requires the object's"))

// --- describe-schema renders `additional` --------------------------
#let described = describe-schema(map(str-type))
#assert(described.contains("*"))
#assert(described.contains("str"))
#let described-true = describe-schema(object((name: str-type), additional: true))
#assert(described-true.contains("*"))
#assert(described-true.contains("any"))

// --- lens "additionalProperties" on array errors --------------------
//
// Arrays use "items"; the additional-schema segment is object-only.
// _descend bails with the "must be \"items\"" message before any
// additional-schema logic runs.
#let arr-src = read("../internal/lens.typ")
#assert(arr-src.contains("lens segment for an array schema must be"))

// --- lens-put trusts the caller for replacement shape --------------
//
// The replacement is written verbatim; lens-put doesn't validate it.
// This pins the contract spelled out in lens.typ's top-of-file
// comment so a future tightening surfaces here.
#let trust-test = lens-put(lens(("tags", "additionalProperties")), tags-schema, 42)
#assert.eq(trust-test.shape.tags.additional, 42)
// The downstream crash that this enables is the caller's
// responsibility — validate would hit a `.kind` access on the int.
// Not exercised here; the pin is on the trust contract itself.

// --- describe-schema with nested map of map ------------------------
//
// Recursive `additional` (map(map(...))) prints the inner "*" too,
// confirming `_describe` recurses through the additional pair.
#let nested-described = describe-schema(map(map(str-type)))
#assert(nested-described.contains("*"))

// --- lens collision: literal "additionalProperties" shape key wins -
//
// Meta-schemas describe properties literally named
// "additionalProperties". Shape-first precedence keeps that literal
// key addressable; the additional schema in that collision case is
// reached via lens-over on the parent (see lens.typ top-of-file).
// Distinct baseline + replacement so the "untouched" assertion below
// can't pass accidentally if lens-put rewrote both.
#let meta-shaped = object(
  (additionalProperties: number-type),
  additional: email-string,
)
// Literal property wins: lens-get returns the shape entry, not `additional`.
#assert.eq(lens-get(lens(("additionalProperties",)), meta-shaped), number-type)
// And lens-put rewrites the shape entry, not `additional`.
#let after-put = lens-put(lens(("additionalProperties",)), meta-shaped, str-type)
#assert.eq(after-put.shape.additionalProperties, str-type)
#assert.eq(after-put.additional, email-string)  // untouched, distinct from the replacement

// --- lens "items" doesn't collide: per-kind dispatch ----------------
//
// "items" on an object kind is a shape key lookup; on an array kind
// it enters `.elem`. The two interpretations live in different
// _descend branches, so a property literally named "items" stays
// addressable on objects.
#let obj-with-items-key = object((items: str-type))
#assert.eq(lens-get(lens(("items",)), obj-with-items-key), str-type)
#let arr = array-of(number-type)
#assert.eq(lens-get(lens(("items",)), arr), number-type)
