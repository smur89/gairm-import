// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".

#let src = read("../internal/lens.typ")

// Object lens diagnostics include the valid-keys list for debuggability.
#assert(src.contains("lens path segment "))
#assert(src.contains("Valid keys: "))

// Prefix-only match dodges the escaped \"items\" quoting in the source.
#assert(src.contains("lens segment for an array schema must be"))

#assert(src.contains("lens cannot descend into a leaf schema"))

// add-field / remove-field share _require-object, so the kind-mismatch
// text is templated. Pin the template AND each call site so the op
// name in the runtime panic survives refactors.
#assert(src.contains("expects an object schema at the lens target"))
#assert(src.contains("_require-object(parent, \"add-field\")"))
#assert(src.contains("_require-object(parent, \"remove-field\")"))

#assert(src.contains("add-field key "))
#assert(src.contains("already in object shape"))
#assert(src.contains("remove-field key "))
#assert(src.contains("not in object shape"))

// set-required uses the same _require-object helper for the
// kind-mismatch case + its own message for the unknown-keys case.
#assert(src.contains("_require-object(parent, \"set-required\")"))
#assert(src.contains("set-required keys not in object shape"))
