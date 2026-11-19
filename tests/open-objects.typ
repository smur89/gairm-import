// `additionalProperties` translation + the `map(value-schema)`
// combinator — #77.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, object, map, array-of, schema-get,
  schema-put, find-paths, describe-schema, string, number,
)

// --- map() convenience ----------------------------------------------

#let str-map = map(string())
#assert.eq(str-map.kind, "object")
#assert.eq(str-map.shape, (:))
#assert.eq(str-map.additional, string())

// All-strings map: arbitrary keys, every value validated.
#assert.eq(validate(str-map, (en: "English", fr: "Français")), ())

#let map-errs = validate(str-map, (en: "English", fr: 42))
#assert.eq(map-errs.len(), 1)
#assert.eq(map-errs.at(0).path, ("fr",))
#assert(map-errs.at(0).message.contains("expected string"))

// Coerce passes through every key, dropping nulls.
#assert.eq(
  coerce(str-map, (a: "x", b: "y", c: none)),
  (a: "x", b: "y"),
)

// --- object with both properties and additional ---------------------

#let mixed = object(
  (name: string()),
  required-keys: ("name",),
  additional: number(),
)

// Declared key validated per properties; extras per `additional`.
#assert.eq(validate(mixed, (name: "Ada", year: 1815, age: 200)), ())

// Wrong type on a declared key still errors via the property schema.
#let mixed-err = validate(mixed, (name: 1, year: 1815))
#assert.eq(mixed-err.len(), 1)
#assert.eq(mixed-err.at(0).path, ("name",))

// Wrong type on an extra errors via `additional`.
#let extra-err = validate(mixed, (name: "Ada", year: "1815"))
#assert.eq(extra-err.len(), 1)
#assert.eq(extra-err.at(0).path, ("year",))
#assert(extra-err.at(0).message.contains("expected number"))

// --- additional: true (pass-through) --------------------------------

#let permissive = object((name: string()), additional: true)
// Any extra accepted without validation.
#assert.eq(
  validate(permissive, (
    name: "Ada",
    anything: (nested: ("array",)),
    other: 42,
  )),
  (),
)

// Coerce preserves extras verbatim — no recursion into them.
#assert.eq(
  coerce(permissive, (name: "Ada", whatever: (a: 1, b: 2))),
  (name: "Ada", whatever: (a: 1, b: 2)),
)

// --- strict path unchanged (no `additional`) ------------------------

#let strict = object((name: string()))
#let strict-err = validate(strict, (name: "Ada", year: 1815))
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
#assert.eq(t-ap-schema.additional, number())

// (e) no properties + additionalProperties: <schema> → pure map
#let t-pure-map = schema-from-json-schema((
  type: "object",
  additionalProperties: (type: "string"),
))
#assert.eq(t-pure-map, map(string()))

// (f) no properties, no additionalProperties → still bails; see
// tests/panics/schema-from-json-schema-object-open.typ.

// `additional` + required-key-not-in-shape is now allowed — the
// extra key gets validated by `additional`, so the construction-time
// subset check is skipped when an additional schema is present.
#let open-required = object(
  (:),
  required-keys: ("id",),
  additional: string(),
)
#assert.eq(open-required.required-keys, ("id",))
// And the runtime still flags it missing if absent…
#let missing = validate(open-required, (:))
#assert.eq(missing.len(), 1)
#assert(missing.at(0).message.contains("missing required key \"id\""))
// …and validates the value against `additional` when present.
#assert.eq(validate(open-required, (id: "abc")), ())
#let wrong-type = validate(open-required, (id: 1))
#assert.eq(wrong-type.len(), 1)
#assert(wrong-type.at(0).message.contains("expected string"))

// --- error path uses the actual key, not "items" --------------------
//
// A pure map of objects: error inside one entry surfaces the real key.
#let book-map = map(object((title: string()), required-keys: ("title",)))
#let bad-books = validate(book-map, (
  one: (title: "Ulysses"),
  two: (title: 42),
))
#assert.eq(bad-books.len(), 1)
#assert.eq(bad-books.at(0).path, ("two", "title"))

// --- constructor: `additional: false` ≡ `none` -----------------------
//
// JSON Schema's `additionalProperties: false` and our `additional: none`
// are semantically identical. The constructor accepts both so callers
// fluent in JSON Schema vocabulary don't trip on the assert.
#let strict-via-false = object((name: string()), additional: false)
#assert("additional" not in strict-via-false)
#let strict-via-none = object((name: string()))
#assert.eq(strict-via-false, strict-via-none)

// --- map(v, required-keys: …) symmetry with object ------------------
#let required-map = map(string(), required-keys: ("id",))
#assert.eq(required-map.required-keys, ("id",))
#assert.eq(required-map.additional, string())
#assert.eq(validate(required-map, (id: "abc", other: "ok")), ())
#let missing-id = validate(required-map, (other: "ok"))
#assert.eq(missing-id.len(), 1)
#assert(missing-id.at(0).message.contains("missing required key \"id\""))

// --- all-none extras leave an empty object -------------------------
//
// Null extras are dropped like declared null keys, but the object
// itself is present, so it stays a (possibly empty) dict.
#assert.eq(coerce(map(string()), (a: none, b: none)), (:))
#assert.eq(
  coerce(
    map(string(), required-keys: (
      "id",
    )),
    (id: "x", a: none, b: none),
  ),
  (id: "x"),
)

// --- introspection: `find-paths` descends into `additional` -----
//
// Path segment is `"additionalProperties"` (matching the JSON Schema
// keyword name, same convention as `"items"` for arrays). The
// emitted path round-trips through `schema-get`.
#let tags-schema = object(
  (name: string(), tags: map(string())),
  required-keys: ("name",),
)
#assert.eq(
  find-paths(tags-schema, string()),
  (("name",), ("tags", "additionalProperties")),
)
// Round-trip: the segment is a real schema path.
#assert.eq(schema-get(tags-schema, ("tags", "additionalProperties")), string())

// Nested `additional` inside `additional` works too.
#let nested-maps = map(map(number()))
#assert.eq(
  find-paths(nested-maps, number()),
  (("additionalProperties", "additionalProperties"),),
)

// --- schema-put: `"additionalProperties"` writes back into `additional` --
#let updated = schema-put(
  tags-schema,
  ("tags", "additionalProperties"),
  number(),
)
#assert.eq(updated.shape.tags.additional, number())
// Shape outside the edited path is untouched.
#assert.eq(updated.shape.name, string())

// --- describe-schema renders `additional` --------------------------
#let described = describe-schema(map(string()))
#assert(described.contains("*"))
#assert(described.contains("string"))
#let described-true = describe-schema(object(
  (name: string()),
  additional: true,
))
#assert(described-true.contains("*"))
#assert(described-true.contains("unknown"))

// schema-put rejects a replacement that is not a schema:
// tests/panics/schema-put-value-not-schema.typ.

// --- describe-schema with nested map of map ------------------------
//
// Recursive `additional` (map(map(...))) prints the inner "*" too,
// confirming `_describe` recurses through the additional pair.
#let nested-described = describe-schema(map(map(string())))
#assert(nested-described.contains("*"))

// --- path collision: literal "additionalProperties" shape key wins -
//
// Meta-schemas describe properties literally named
// "additionalProperties". Shape-first precedence keeps that literal
// key addressable; the additional schema in that collision case is
// reached via schema-update on the parent (see edit.typ top-of-file).
// Distinct baseline + replacement so the "untouched" assertion below
// can't pass accidentally if schema-put rewrote both.
#let meta-shaped = object(
  (additionalProperties: number()),
  additional: string(format: "email"),
)
// Literal property wins: schema-get returns the shape entry, not `additional`.
#assert.eq(schema-get(meta-shaped, ("additionalProperties",)), number())
// And schema-put rewrites the shape entry, not `additional`.
#let after-put = schema-put(meta-shaped, ("additionalProperties",), string())
#assert.eq(after-put.shape.additionalProperties, string())
#assert.eq(after-put.additional, string(format: "email"))  // untouched, distinct from the replacement

// --- path "items" doesn't collide: per-kind dispatch ----------------
//
// "items" on an object kind is a shape key lookup; on an array kind
// it enters `.elem`. The two interpretations live in different
// _descend branches, so a property literally named "items" stays
// addressable on objects.
#let obj-with-items-key = object((items: string()))
#assert.eq(schema-get(obj-with-items-key, ("items",)), string())
#let arr = array-of(number())
#assert.eq(schema-get(arr, ("items",)), number())
