// expect: coerce expected a boolean, got integer.
#import "../../lib.typ": bool-type, coerce, object
#coerce((a: 1), schema: object((a: bool-type)))
