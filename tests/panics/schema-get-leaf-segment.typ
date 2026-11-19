// expect: schema-get path segment "b" cannot enter a string schema, which has no children.
#import "../../lib.typ": schema-get, object, string
#schema-get(object((a: string())), ("a", "b"))
