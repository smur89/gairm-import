// expect: number() minimum must be a number, got: float.nan.
#import "../../lib.typ": number
#number(minimum: float.nan)
