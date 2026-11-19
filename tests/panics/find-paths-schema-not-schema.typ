// expect: find-paths schema must be a schema, got: "x".
#import "../../lib.typ": find-paths, string
#find-paths("x", string())
