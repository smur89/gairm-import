// expect: lens segment for a not schema must be "not", got 0.
#import "../../lib.typ": lens, lens-get, not-of, object, str-type
#lens-get(lens(("a", 0)), object((a: not-of(str-type))))
