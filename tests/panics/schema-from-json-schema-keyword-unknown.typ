// expect: unsupported JSON Schema keyword(s): "minLenght".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string", minLenght: 1)),
))
