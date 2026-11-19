// expect: schema-get path must be an array of path segments, got: (lens: ("a",)).
// The `(lens: path)` form is gone in 1.0: pass the path itself.
#import "../../lib.typ": schema-get, object, string
#schema-get(object((a: string())), (lens: ("a",)))
