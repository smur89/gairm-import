// expect: schema-from-json-schema — keyword(s) "minimum" are only supported on `type: "number"` or `type: "integer"` schemas
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: ("boolean", "null"), minimum: 1))
