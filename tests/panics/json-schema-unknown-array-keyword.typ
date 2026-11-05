// expect: unsupported JSON Schema keyword(s): "contains".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "array",
  items: (type: "string"),
  contains: (const: "a"),
))
