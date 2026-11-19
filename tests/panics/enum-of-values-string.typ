// expect: enum-of() values must be a non-empty array, got: "ab". Write ("ab",) for one value.
#import "../../lib.typ": enum-of
#enum-of("ab")
