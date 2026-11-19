// expect: add-field path must be an object schema, got: a string schema.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), ("a", "k"), string())
