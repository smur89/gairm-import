// expect: set-required path segment "x" cannot enter an integer schema, which has no children.
#import "../../lib.typ": set-required, object, integer
#set-required(object((n: integer())), ("n", "x"), ())
