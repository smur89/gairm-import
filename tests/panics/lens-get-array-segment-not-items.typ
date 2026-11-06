// expect: lens segment for an array schema must be "items", got "0".
#import "../../lib.typ": array-of, lens-get, object, str-type
#lens-get(object((xs: array-of(str-type))), ("xs", "0"))
