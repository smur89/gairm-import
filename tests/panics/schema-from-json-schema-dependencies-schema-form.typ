// expect: the schema form of "dependencies" (for "a"). Conditional schemas are out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependencies: (a: (required: ("b",))),
))
