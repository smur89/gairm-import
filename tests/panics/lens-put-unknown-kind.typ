// expect: lens-put value must be a schema; got: (kind: "bogus").
#import "../../lib.typ": lens, lens-put, object, str-type
#lens-put(lens(("a",)), object((a: str-type)), (kind: "bogus"))
