// expect: remove-field path must be a field's path, ending in its name (a string), got: ("a", 0).
// A union member is not a field: remove it with schema-update on the union.
#import "../../lib.typ": remove-field, object, any-of, string, integer
#remove-field(object((a: any-of(string(), integer()))), ("a", 0))
