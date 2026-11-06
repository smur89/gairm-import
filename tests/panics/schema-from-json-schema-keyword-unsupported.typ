// expect: unsupported JSON Schema keyword: "if". Conditional schemas (if/then/else, dependentSchemas, schema-form dependencies) are out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", "if": (type: "string")))
