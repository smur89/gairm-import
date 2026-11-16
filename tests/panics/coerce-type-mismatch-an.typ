// expect: coerce at a: expected an object, got string.
#import "../../lib.typ": coerce, object, string
#coerce((a: "x"), schema: object((a: object((b: string())))))
