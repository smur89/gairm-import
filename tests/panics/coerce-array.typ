// expect: coerce expected an array, got string.
#import "../../lib.typ": array-of, coerce, object, str-type
#coerce((a: "x"), schema: object((a: array-of(str-type))))
