// expect: validate schema field "pattern" must be a regex or a string, got: none.
// Hand-built: a stored null pattern fails up front, not at `match`.
#import "../../lib.typ": validate
#validate((kind: "string", pattern: none), "x")
