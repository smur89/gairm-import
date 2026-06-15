// Pins the enum-of / const-of contract: membership gates validation;
// coerce mirrors the check; null-as-absent absorbs enum-member none.

#import "../lib.typ": enum-of, const-of, object, validate, coerce

// ---- enum-of: string members ---------------------------------------

#let fluency = enum-of(("native", "fluent", "intermediate", "beginner"))
#assert.eq(fluency.kind, "enum")
#assert.eq(fluency.values, ("native", "fluent", "intermediate", "beginner"))

#let fluency-schema = object((fluency: fluency))
#assert.eq(validate((fluency: "native"), schema: fluency-schema), ())
#assert.eq(validate((fluency: "fluent"), schema: fluency-schema), ())

#let errs = validate((fluency: "average"), schema: fluency-schema)
#assert.eq(errs.len(), 1)
#assert.eq(errs.at(0).path, ("fluency",))
#assert(errs.at(0).message.contains("expected one of"))
#assert(errs.at(0).message.contains("\"native\""))
#assert(errs.at(0).message.contains("got \"average\""))

// ---- enum-of: number members ---------------------------------------

#let rating = enum-of((1, 2, 3, 4, 5))
#let rating-schema = object((rating: rating))
#assert.eq(validate((rating: 5), schema: rating-schema), ())

#let num-errs = validate((rating: 6), schema: rating-schema)
#assert.eq(num-errs.len(), 1)
#assert(num-errs.at(0).message.contains("expected one of"))
#assert(num-errs.at(0).message.contains("got 6"))

// ---- enum-of: mixed-type members -----------------------------------

#let mixed = enum-of(("auto", 0, 100, none))
#let mixed-schema = object((zoom: mixed))
#assert.eq(validate((zoom: "auto"), schema: mixed-schema), ())
#assert.eq(validate((zoom: 0), schema: mixed-schema), ())
#assert.eq(validate((zoom: 100), schema: mixed-schema), ())
// `none` is absorbed by validate's null-as-absent early-return —
// `zoom: none` reads as "key absent", not "matches the none member".
#assert.eq(validate((zoom: none), schema: mixed-schema), ())

#let mixed-errs = validate((zoom: "max"), schema: mixed-schema)
#assert.eq(mixed-errs.len(), 1)

// ---- const-of: singleton-enum shortcut -----------------------------

#let version = const-of("v1.0.0")
#assert.eq(version.kind, "enum")
#assert.eq(version.values, ("v1.0.0",))

#let meta-schema = object((version: version))
#assert.eq(validate((version: "v1.0.0"), schema: meta-schema), ())

#let const-errs = validate((version: "v2.0.0"), schema: meta-schema)
#assert.eq(const-errs.len(), 1)
#assert(const-errs.at(0).message.contains("\"v1.0.0\""))

// ---- Empty enum rejects every input --------------------------------

#let empty = enum-of(())
#let empty-schema = object((x: empty))
#let empty-errs = validate((x: "anything"), schema: empty-schema)
#assert.eq(empty-errs.len(), 1)
#assert(empty-errs.at(0).message.contains("expected one of"))

// ---- Coercion is membership-checked pass-through -------------------

#assert.eq(coerce((fluency: "native"), schema: fluency-schema).fluency, "native")
#assert.eq(coerce((rating: 5), schema: rating-schema).rating, 5)
#assert.eq(coerce((version: "v1.0.0"), schema: meta-schema).version, "v1.0.0")
