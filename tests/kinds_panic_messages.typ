// Source-level pin pattern — see tests/lens_panic_messages.typ for
// the basic shape and tests/json_schema_panic_messages.typ for the
// coverage + substring rules.

#let src = read("../internal/kinds.typ")

// Both `object()` construction-time guards; prefix included so a
// project-wide rename surfaces here.
#assert(src.contains("gairm-import: object() additional must be none, false, true, or a schema dict"))
#assert(src.contains("gairm-import: object() required-keys references keys not in shape"))
