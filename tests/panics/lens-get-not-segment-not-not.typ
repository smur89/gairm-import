// expect: lens segment for a not schema must be "not", got 0.
#import "../../lib.typ": lens-get, not-of, object, str-type
#lens-get(object((a: not-of(str-type))), ("a", 0))
