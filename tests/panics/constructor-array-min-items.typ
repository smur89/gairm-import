// expect: array-of() min-items must be a non-negative integer, got: -1.
#import "../../lib.typ": array-of, str-type
#array-of(str-type, min-items: -1)
