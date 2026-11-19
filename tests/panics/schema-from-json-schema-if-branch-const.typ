// expect: at /then: the siblings of "if" and its branches must all be object schemas, got: an enum ({"a": 1}) schema.
// A const branch is not read as combined with its siblings' properties.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "integer")),
  additionalProperties: false,
  "if": (properties: (a: (const: 1))),
  then: (const: (a: 1)),
))
