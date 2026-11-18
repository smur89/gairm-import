// expect: got: a node of kind 1.
// A malformed query reaches the package panic, not a raw error.
#import "../../lib.typ": paths-of-kind, string
#paths-of-kind(string(), (kind: 1))
