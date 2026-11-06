// expect: coerce at a: expected one of "x", "y", got integer.
// validate reports `type` here (no listed value is a number), but
// coerce names the values, as it does for an `enum` miss.
#import "../../lib.typ": coerce, enum-of, object
#coerce((a: 1), schema: object((a: enum-of(("x", "y")))))
