// expect: coerce at a: expected an object, got string.
#import "../../lib.typ": coerce, object, string
#coerce(object((a: object((b: string())))), (a: "x"))
