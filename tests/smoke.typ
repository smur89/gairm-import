// Smoke test: lib.typ parses and exports the v0.1 public API —
// canonical wrappers + BYO surface (engines, combinators, schema,
// report formatter).

#import "../lib.typ": (
  validate-resume, coerce-resume, parse-resume,
  validate, coerce, format-errors,
  resume-schema, object, array-of, str-type, content-type, number-type,
  schema-from-json-schema,
)
