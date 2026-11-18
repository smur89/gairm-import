// expect: remove-field key must be a string, got: 1.
#import "../../lib.typ": remove-field, object, string
#remove-field(object((a: string())), (), 1)
