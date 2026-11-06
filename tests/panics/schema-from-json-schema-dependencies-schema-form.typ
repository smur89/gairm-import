// expect: the schema form of "dependencies" (for "a"). dependentSchemas and the schema form of dependencies are out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependencies: (a: (required: ("b",))),
))
