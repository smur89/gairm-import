// expect: lens-put value must be a schema; got: 1. Build schemas with the constructors.
#import "../../lib.typ": lens-put, object, str-type
#lens-put(object((a: str-type)), ("a",), 1)
