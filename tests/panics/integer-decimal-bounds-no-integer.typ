// expect: integer() minimum (decimal("1.5")) and maximum (1.7) leave no integer.
#import "../../lib.typ": integer
#integer(minimum: decimal("1.5"), maximum: 1.7)
