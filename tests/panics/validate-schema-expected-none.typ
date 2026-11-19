// expect: validate schema field "expected" must be a string, got: none.
#import "../../lib.typ": validate
#validate((kind: "string", pattern: regex("^x"), expected: none), "y")
