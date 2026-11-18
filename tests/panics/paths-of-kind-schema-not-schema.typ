// expect: paths-of-kind schema must be a schema, got: "x".
#import "../../lib.typ": paths-of-kind, string
#paths-of-kind("x", string())
