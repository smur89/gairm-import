// expect: add-field key must be a string, got: 1.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), (), 1, string())
