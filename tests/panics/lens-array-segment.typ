// expect: lens segment for an array schema must be "items", got "0".
#import "../../lib.typ": array-of, lens, lens-get, object, str-type
#lens-get(lens(("xs", "0")), object((xs: array-of(str-type))))
