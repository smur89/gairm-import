// expect: find-paths query must be a schema, got: (kind: 1).
// A malformed query fails the schema check, in the package's words.
#import "../../lib.typ": find-paths, string
#find-paths(string(), (kind: 1))
