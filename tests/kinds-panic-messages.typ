// Source-level pin pattern — see tests/lens-panic-messages.typ for
// the basic shape and tests/json-schema-panic-messages.typ for the
// coverage + substring rules.

#let src = read("../internal/kinds.typ")

// Both `object()` construction-time guards; prefix included so a
// project-wide rename surfaces here.
#assert(
  src.contains(
    "gairm-import: object() additional must be none, false, true, or a schema dict",
  ),
)
#assert(
  src.contains(
    "gairm-import: object() required-keys references keys not in shape",
  ),
)

// Composition constructors (#108) — shared member guard + not-of's own.
#assert(src.contains("members must be a non-empty array of schema dicts"))
#assert(src.contains("gairm-import: not-of member must be a schema dict"))
