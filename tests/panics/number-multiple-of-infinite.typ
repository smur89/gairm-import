// expect: number() multiple-of must be finite, got: float.inf.
// A multiple of infinity would take every finite value.
#import "../../lib.typ": number
#number(multiple-of: calc.inf)
