// expect: array-of() min-items (3) > max-items (2) is unsatisfiable.
#import "../../lib.typ": array-of, str-type
#array-of(str-type, min-items: 3, max-items: 2)
