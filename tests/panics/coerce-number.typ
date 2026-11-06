// expect: coerce at a: expected a number, got string.
#import "../../lib.typ": coerce, number-type, object
#coerce((a: "x"), schema: object((a: number-type)))
