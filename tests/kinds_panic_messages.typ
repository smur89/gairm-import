// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `assert(...)` site in `internal/kinds.typ`
// is pinned below. A new constructor guard added in an MR that
// touches that file should land its pin in the same MR.
//
// `kinds.typ` is the source of schema-dict constructors. The two
// `object()` asserts catch hand-built schema typos at construction
// time rather than as phantom validation errors deep in the engine.

#let src = read("../internal/kinds.typ")

// `object()` rejects `additional` values that aren't `none`, `false`,
// `true`, or a schema dict with a `kind` field. The wider set
// (`false` accepted as a synonym for `none`) means callers fluent in
// JSON Schema vocab can pass either.
#assert(src.contains("additional must be none, false, true, or a schema dict"))

// `object()` rejects `required-keys` that aren't a subset of `shape`
// when `additional` is unset — required keys must be declared. With
// `additional` set, the subset check is skipped (extras are covered
// by the additional schema).
#assert(src.contains("required-keys references keys not in shape"))
