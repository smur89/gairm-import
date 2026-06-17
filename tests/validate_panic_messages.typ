// Source-level pin pattern — see tests/lens_panic_messages.typ for
// the basic shape and tests/json_schema_panic_messages.typ for the
// coverage + substring rules.
//
// `_validate` returns error records via `_type-error` / `_err` —
// those are exercised behaviorally throughout tests/validate_*.typ.
// This file covers the lone genuine `panic`.

#let src = read("../internal/validate.typ")

// Prefix included so a project-wide rename surfaces here.
#assert(src.contains("gairm-import: internal — unknown schema kind"))
