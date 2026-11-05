// expect: unsupported JSON Schema keyword: "dependentSchemas". Conditional schemas (if/then/else, dependentSchemas, schema-form dependencies) are out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependentSchemas: (a: (required: ("b",))),
))
