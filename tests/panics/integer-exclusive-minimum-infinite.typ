// expect: integer() exclusive-minimum (float.inf) leaves no integer.
#import "../../lib.typ": integer
#integer(exclusive-minimum: calc.inf)
