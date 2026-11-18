// expect: add-field location must be an object schema, got: a union schema.
#import "../../lib.typ": add-field, object, any-of, string, integer
#add-field(object((a: any-of(string(), integer()))), ("a",), "x", string())
