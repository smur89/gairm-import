// expect: coerce at a: expected an object, got string.
#import "../../lib.typ": coerce, object, str-type
#coerce((a: "x"), schema: object((a: object((b: str-type)))))
