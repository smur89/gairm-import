// expect: coerce at a: expected null, got integer.
#import "../../lib.typ": coerce, null-type, object
#coerce((a: 1), schema: object((a: null-type)))
