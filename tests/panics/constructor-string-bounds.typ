// expect: string() min-length (5) > max-length (3) is unsatisfiable.
#import "../../lib.typ": string
#string(min-length: 5, max-length: 3)
