// expect: lens-get path segment must be "items" for an array schema, got: "0".
#import "../../lib.typ": array-of, lens-get, object, string
#lens-get(object((xs: array-of(string()))), ("xs", "0"))
