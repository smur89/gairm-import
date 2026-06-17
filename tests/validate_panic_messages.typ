// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `panic(...)` site in `internal/validate.typ`
// is pinned below. A new panic added in an MR that touches that file
// should land its pin in the same MR.
//
// **Note on _type-error / _err:** `_validate` doesn't bail on bad
// input — it returns error RECORDS via `_type-error` and `_err`.
// Those are tested behaviorally (input → expected error message)
// throughout `tests/validate_*.typ`, so the substring-pin pattern
// isn't needed for them; this file covers only the genuine panics.

#let src = read("../internal/validate.typ")

// Dispatch fallthrough at the end of `_validate`: a schema dict with
// a `kind` the engine doesn't recognise. Should never fire on a
// validated translator output, but pins the diagnostic for direct
// callers passing hand-built schema dicts.
#assert(src.contains("unknown schema kind"))
