// expect: schema-from-json-schema — "dependencies" for "a" must be an array of field names, got: "b".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string"), b: (type: "string")),
  dependencies: (a: "b"),
))
