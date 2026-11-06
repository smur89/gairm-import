// expect: lens-put value must be a schema; got: (lens: ("a",)).
#import "../../lib.typ": lens, lens-put, object, str-type
#lens-put(object((a: str-type)), ("a",), lens(("a",)))
