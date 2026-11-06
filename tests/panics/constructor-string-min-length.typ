// expect: string() min-length must be a non-negative integer, got: -1.
#import "../../lib.typ": string
#string(min-length: -1)
