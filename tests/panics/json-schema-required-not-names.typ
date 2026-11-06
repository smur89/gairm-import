// expect: "required" must be an array of key names, got: ("a", 1).
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  required: ("a", 1),
))
