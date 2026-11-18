// expect: lens-get path segment must be a member index, 0 to 1, for a union schema, got: 2.
#import "../../lib.typ": any-of, lens-get, object, string, number
#lens-get(object((a: any-of((string(), number())))), ("a", 2))
