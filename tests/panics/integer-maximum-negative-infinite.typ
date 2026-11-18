// expect: integer() maximum (-float.inf) leaves no integer.
#import "../../lib.typ": integer
#integer(maximum: -calc.inf)
