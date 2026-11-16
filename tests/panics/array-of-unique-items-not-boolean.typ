// expect: array-of() unique-items must be a boolean, got: 1.
#import "../../lib.typ": array-of, string
#array-of(string(), unique-items: 1)
