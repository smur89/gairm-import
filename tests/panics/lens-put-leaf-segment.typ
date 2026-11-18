// expect: lens-put path segment "b" cannot enter a string schema, which has no children.
#import "../../lib.typ": lens-put, object, string, number
#lens-put(object((a: string())), ("a", "b"), number())
