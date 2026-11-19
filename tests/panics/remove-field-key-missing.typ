// expect: remove-field key "b" not in object shape.
#import "../../lib.typ": object, remove-field, string
#remove-field(object((a: string())), (), "b")
