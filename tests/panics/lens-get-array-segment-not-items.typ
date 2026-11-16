// expect: lens segment for an array schema must be "items", got "0".
#import "../../lib.typ": array-of, lens-get, object, string
#lens-get(object((xs: array-of(string()))), ("xs", "0"))
