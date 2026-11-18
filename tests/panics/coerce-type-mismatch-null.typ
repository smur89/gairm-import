// expect: coerce at a: expected null, got integer.
#import "../../lib.typ": coerce, null-type, object
#coerce(object((a: null-type)), (a: 1))
