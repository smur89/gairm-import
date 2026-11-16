// expect: lens cannot descend into a leaf schema
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), ("a", "b"))
