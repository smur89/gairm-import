// expect: lens-get path segment "b" cannot enter a string schema, which has no children.
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), ("a", "b"))
