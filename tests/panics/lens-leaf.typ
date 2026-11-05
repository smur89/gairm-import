// expect: lens cannot descend into a leaf schema
#import "../../lib.typ": lens, lens-get, object, str-type
#lens-get(lens(("a", "b")), object((a: str-type)))
