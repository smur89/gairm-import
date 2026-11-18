// expect: add-field location must be an object schema, got: a string schema.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), (lens: ("a",)), "k", string())
