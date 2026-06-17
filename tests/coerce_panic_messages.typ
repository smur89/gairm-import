// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `panic(...)` and `assert(...,
// message: _expect(...))` site in `internal/coerce.typ` is pinned
// below. A new bail site added in an MR that touches that file
// should land its pin in the same MR.
//
// `_coerce` assumes input has passed `_validate`, so its assertions
// guard direct-coerce callers who skipped validation. Each `_expect`
// argument identifies the expected type; pinning the per-call
// literals catches a refactor that drops one of the dispatch branches
// or renames the expected-type wording.

#let src = read("../internal/coerce.typ")

// --- _expect template ----------------------------------------------
//
// `_expect(expected, value)` is the shared message constructor.
// Pinning prefix + suffix guards the template even if the
// per-branch `expected` argument changes.
#assert(src.contains("gairm-import: coerce expected"))
#assert(src.contains("Run validate(data) first"))

// --- per-branch expected-type literals -----------------------------

#assert(src.contains("_expect(\"a string\""))
#assert(src.contains("_expect(\"a number\""))
#assert(src.contains("_expect(\"a boolean\""))
#assert(src.contains("_expect(\"null\""))
// `enum`'s expected is built dynamically — `"one of " + values...`
// — so pin the literal prefix instead.
#assert(src.contains("\"one of \""))
#assert(src.contains("_expect(\"an array\""))
#assert(src.contains("_expect(\"an object\""))

// --- terminal dispatch fallthrough ---------------------------------

// A schema dict with a `kind` the engine doesn't recognise. Should
// never fire on a validated translator output, but pins the
// diagnostic for direct callers passing hand-built schema dicts.
#assert(src.contains("unknown schema kind"))
