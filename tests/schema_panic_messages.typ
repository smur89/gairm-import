// Source-level pin pattern — see tests/lens_panic_messages.typ for
// the basic shape and tests/json_schema_panic_messages.typ for the
// coverage + substring rules.
//
// `_override-fold`'s assert is exercised behaviorally by
// tests/schema_strict.typ (loads the strict variant, would trip on
// upstream drift). These pins additionally catch reword refactors.

#let src = read("../internal/schema.typ")

// `"gairm-import: "` (with trailing space) is unique to schema.typ;
// pinning it guards the prefix without coupling to `list-name`.
#assert(src.contains("\"gairm-import: \""))
#assert(src.contains("must target"))
#assert(src.contains("leaves only"))
#assert(src.contains("Audit upstream schema bump"))
