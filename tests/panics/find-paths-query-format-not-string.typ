// expect: find-paths query field "format" must be one of "date"
// A malformed query field fails in the package's words.
#import "../../lib.typ": find-paths, string
#find-paths(string(), (kind: "string", format: 5))
