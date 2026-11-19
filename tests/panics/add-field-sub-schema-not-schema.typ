// expect: add-field field "b" must be a schema, got: 5.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), ("b",), 5)
