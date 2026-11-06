// expect: schema-from-json-schema — keyword(s) "properties" are only supported on `type: "object"` schemas
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "string",
  properties: (a: (type: "string")),
  minItems: 2,
))
