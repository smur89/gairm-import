// expect: lens segment for a not schema must be "not", got 0.
#import "../../lib.typ": lens-get, not-of, object, string
#lens-get(object((a: not-of(string()))), ("a", 0))
