// expect: lens-get path segment must be "not" for a not schema, got: 0.
#import "../../lib.typ": lens-get, not-of, object, string
#lens-get(object((a: not-of(string()))), ("a", 0))
