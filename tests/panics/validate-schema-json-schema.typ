// expect: validate schema must be a schema, got: a JSON Schema document. Translate it with schema-from-json-schema(..) first.
// A JSON Schema document is named, not dumped, and pointed at the translator.
#import "../../lib.typ": validate
#validate(
  ("$schema": "http://json-schema.org/draft-07/schema#", type: "string"),
  "x",
)
