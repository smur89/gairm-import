// expect: coerce at a: expected null, got integer.
#import "../../lib.typ": coerce, null, object
#coerce(object((a: null())), (a: 1))
