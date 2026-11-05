// expect: coerce expected one of "x", "y", got string.
#import "../../lib.typ": coerce, enum-of, object
#coerce((a: "z"), schema: object((a: enum-of(("x", "y")))))
