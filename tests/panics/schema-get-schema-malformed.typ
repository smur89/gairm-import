// expect: schema-get schema at ("a",) field "elem" must be a schema, got: missing.
#import "../../lib.typ": schema-get
#schema-get((kind: "object", shape: (a: (kind: "array"))), ("a",))
