// expect: enum-of() values must be an array, got: "ab". Write ("ab",) for one value.
#import "../../lib.typ": enum-of
#enum-of("ab")
