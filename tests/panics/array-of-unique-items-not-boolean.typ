// expect: array-of() unique-items must be a boolean, got: 1.
#import "../../lib.typ": array-of, str-type
#array-of(str-type, unique-items: 1)
