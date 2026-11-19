// expect: schema-from-json-schema — at the root: keyword(s) "minimum" are only supported on `type: "number"` or `type: "integer"` schemas, but this node's `type` is ["boolean", "null"]
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: ("boolean", "null"), minimum: 1))
