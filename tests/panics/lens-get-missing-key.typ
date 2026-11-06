// expect: lens path segment "b" not in object shape. Valid keys: a, xs.
#import "../../lib.typ": array-of, lens-get, object, str-type
#lens-get(object((a: str-type, xs: array-of(str-type))), ("b",))
