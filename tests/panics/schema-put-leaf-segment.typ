// expect: schema-put path segment "b" cannot enter a string schema, which has no children.
#import "../../lib.typ": schema-put, object, string, number
#schema-put(object((a: string())), ("a", "b"), number())
