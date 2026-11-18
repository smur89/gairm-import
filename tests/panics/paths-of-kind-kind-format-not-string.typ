// expect: string schema format must be one of "date"
// A malformed query field fails in the package's words.
#import "../../lib.typ": paths-of-kind, string
#paths-of-kind(string(), (kind: "string", format: 5))
