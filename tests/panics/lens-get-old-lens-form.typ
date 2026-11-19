// expect: lens-get takes a schema, then a path (an array of segments); got a schema and a dictionary.
// The `(lens: path)` form is gone in 1.0: pass the path itself.
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), (lens: ("a",)))
