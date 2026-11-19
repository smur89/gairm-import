// expect: validate schema field "shape" must be a dictionary of field name to schema, got: missing.
// Hand-built: a node missing a field its walk reads fails up front.
#import "../../lib.typ": validate
#validate((kind: "object"), (a: 1))
