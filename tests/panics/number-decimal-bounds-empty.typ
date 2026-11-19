// expect: number() minimum (1.6) > maximum (decimal("1.5")) is unsatisfiable.
#import "../../lib.typ": number
#number(minimum: 1.6, maximum: decimal("1.5"))
