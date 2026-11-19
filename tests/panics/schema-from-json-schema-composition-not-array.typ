// expect: at the root: "anyOf" must be a non-empty array of schemas, got: {"type": "string"}.
// The value is quoted as JSON writes it.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((anyOf: (type: "string")))
