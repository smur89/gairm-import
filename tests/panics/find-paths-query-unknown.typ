// expect: got: a node of kind 1.
// A malformed query reaches the package panic, not a raw error.
#import "../../lib.typ": find-paths, string
#find-paths(string(), (kind: 1))
