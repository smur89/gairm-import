// expect: add-field key "a" already in object shape.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), (lens: ()), "a", string())
