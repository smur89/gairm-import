// expect: lens cannot descend into a leaf schema
#import "../../lib.typ": lens-get, object, str-type
#lens-get(object((a: str-type)), ("a", "b"))
