// Smoke test: lib.typ parses and exports the v0.1 public API —
// canonical wrappers + BYO surface (engines, combinators, schema,
// report formatter).

#import "../lib.typ": (
  validate, coerce, parse, format-errors, resume-schema, resume-schema-strict,
  object, array-of, map, str-type, content-type, number-type, integer-type,
  bool-type, null-type, date-string, datetime-string, uri-string, email-string,
  pattern-string, enum-of, const-of, schema-from-json-schema, lens, lens-get,
  lens-put, lens-over, lens-then, add-field, remove-field, set-required,
  unset-required, describe-schema, paths-of-kind, kind-at, path-to-pointer,
  pointer-to-path,
)
