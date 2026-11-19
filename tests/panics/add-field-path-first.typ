// expect: add-field takes a schema, then a path (an array of segments); got a path and a schema.
#import "../../lib.typ": add-field, object, string
#add-field(("a",), object((:)), string())
