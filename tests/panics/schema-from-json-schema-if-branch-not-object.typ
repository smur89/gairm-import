// expect: at /then: the siblings of "if" and its branches must all be object schemas, got: a string schema.
// A branch of another type is named as written, not by the keywords its
// siblings would have lent it.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "integer")),
  additionalProperties: false,
  "if": (properties: (a: (const: 1))),
  then: (type: "string"),
))
