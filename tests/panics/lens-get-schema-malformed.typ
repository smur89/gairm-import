// expect: lens-get schema at ("a",) field "elem" must be a schema, got: missing.
#import "../../lib.typ": lens-get
#lens-get((kind: "object", shape: (a: (kind: "array"))), ("a",))
