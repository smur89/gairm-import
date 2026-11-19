// expect: remove-field path must be a field's path, ending in its name (a string), got: ("a", -1).
// A negative int names no field, as no JSON Pointer spells one.
#import "../../lib.typ": remove-field, object, string
#remove-field(object((a: object((b: string())))), ("a", -1))
