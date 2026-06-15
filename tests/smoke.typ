// Smoke test: lib.typ parses and exports the v0.1 public API —
// canonical wrappers + BYO surface (engines, combinators, schema,
// report formatter).

#import "../lib.typ": (
  validate, coerce, parse, format-errors,
  resume-schema, resume-schema-strict,
  object, array-of, str-type, content-type, number-type,
  date-string, uri-string, email-string,
  enum-of, const-of,
  schema-from-json-schema,
  lens, lens-get, lens-put, lens-over, lens-then,
  add-field, remove-field, set-required,
)
