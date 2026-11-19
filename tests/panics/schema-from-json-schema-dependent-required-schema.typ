// expect: at the root: "dependentRequired" for "a" must be an array of key names, got: {"type": "string"}.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependentRequired: (a: (type: "string")),
))
