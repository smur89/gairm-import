// expect: lens segment for a union schema must be a member index, 0 to 1, got 2.
#import "../../lib.typ": any-of, lens-get, number-type, object, str-type
#lens-get(object((a: any-of((str-type, number-type)))), ("a", 2))
