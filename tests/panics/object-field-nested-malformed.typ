// expect: object() field "a" at ("b",) must be a schema, got: (type: "string").
// A hand-built node nested in a sub-schema is found, and named by path.
#import "../../lib.typ": object
#object((a: (kind: "object", shape: (b: (type: "string")))))
