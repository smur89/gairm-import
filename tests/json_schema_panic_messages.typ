// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// Each assert picks a unique unescaped substring of its target
// message — escaped quotes (\") in the source bytes don't round-trip
// through Typst's string-literal escape processing, so prefix-only
// matches sidestep that.

#let src = read("../internal/json-schema.typ")

// $ref scheme is restricted to internal `#/...` references — external
// $refs would need a fetcher the engine deliberately doesn't have.
#assert(src.contains("only internal $ref (starting with"))

// `seen` cycle detection. If a $ref chain revisits a previously-seen
// reference the resolver panics with the chain in the message before
// Typst's recursion limit fires deep in the stack — a refactor that
// stopped threading `seen` through would silently break this guard.
#assert(src.contains("cyclic $ref detected"))

// `#/` (without a JSON Pointer) would self-resolve to the root and
// loop forever; rejected before the cycle check runs because the
// `seen` list is empty at the very first lookup.
#assert(src.contains("cannot reference the document root"))

// Composition / conditional keywords are deliberately out of scope.
// The message names allOf/anyOf/oneOf explicitly so the reader knows
// what *is* expected to surface here on bumps to draft 2020-12.
#assert(src.contains("unsupported JSON Schema keyword"))
#assert(src.contains("Composition keywords (allOf/anyOf/oneOf)"))

// Fully-open object schemas (`type: "object"` with neither
// `properties` nor `additionalProperties`) are rejected at translate
// time — the engine is strict by design and a silently-open object
// would invert the intent.
#assert(src.contains("open object schemas"))
#assert(src.contains("must be declared or covered"))
