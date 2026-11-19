// expect: number() multiple-of must be > 0, got: decimal("0").
#import "../../lib.typ": number
#number(multiple-of: decimal("0"))
