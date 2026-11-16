// expect: lens path segment "b" not in object shape. Valid keys: a, xs.
#import "../../lib.typ": array-of, lens-get, object, string
#lens-get(object((a: string(), xs: array-of(string()))), ("b",))
