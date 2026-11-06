// expect: lens-put value must be a schema; got: 1. Build schemas with the constructors.
#import "../../lib.typ": lens, lens-put, object, str-type
#lens-put(lens(("a",)), object((a: str-type)), 1)
