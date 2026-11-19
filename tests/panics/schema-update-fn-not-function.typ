// expect: schema-update fn must be a function from the node to its replacement, got: 5.
#import "../../lib.typ": schema-update, object, string
#schema-update(object((a: string())), ("a",), 5)
