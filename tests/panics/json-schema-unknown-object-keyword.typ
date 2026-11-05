// expect: unsupported JSON Schema keyword(s): "minProperties".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  minProperties: 1,
))
