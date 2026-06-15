// Source-level pins on the lens panic messages. Typst can't catch
// panics, so the closest we can do is assert the diagnostic text is
// present in lens.typ — a future refactor that drops or rewords a
// message trips this test.

#let src = read("../internal/lens.typ")

// Invalid path segment on an object schema lists the valid keys so a
// typo is debuggable.
#assert(src.contains("lens path segment "))
#assert(src.contains("Valid keys: "))

// Array schema rejects any segment other than "items". Match just
// the prefix because the source contains escaped \"items\" — keeping
// the assertion robust to quoting changes in the message.
#assert(src.contains("lens segment for an array schema must be"))

// Descending past a leaf is explicitly disallowed.
#assert(src.contains("lens cannot descend into a leaf schema"))

// add-field / remove-field reject non-object targets and key
// collisions / absences with named messages.
#assert(src.contains("add-field expects an object schema"))
#assert(src.contains("add-field key "))
#assert(src.contains("already in object shape"))
#assert(src.contains("remove-field expects an object schema"))
#assert(src.contains("remove-field key "))
#assert(src.contains("not in object shape"))
