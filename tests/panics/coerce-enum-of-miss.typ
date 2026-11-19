// expect: coerce at a: expected one of "x", "y", got 1.
// validate reports `type` here (no listed value is a number), but
// coerce names the values, as it does for an `enum` miss.
#import "../../lib.typ": coerce, enum-of, object
#coerce(object((a: enum-of(("x", "y")))), (a: 1))
