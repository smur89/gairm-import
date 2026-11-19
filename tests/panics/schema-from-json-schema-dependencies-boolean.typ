// expect: unsupported JSON Schema keyword: the schema form of "dependencies" (for "a").
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependencies: (a: true),
))
