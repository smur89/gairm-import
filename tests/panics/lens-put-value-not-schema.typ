// expect: lens-put value must be a schema, got: 1. Build schemas with the constructors.
#import "../../lib.typ": lens-put, object, string
#lens-put(object((a: string())), ("a",), 1)
