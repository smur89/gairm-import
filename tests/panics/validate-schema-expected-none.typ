// expect: validate schema field "expected" must be a string, got: none.
#import "../../lib.typ": validate
#validate((kind: "string", pattern: "^x", expected: none), "y")
