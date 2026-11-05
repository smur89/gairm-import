// expect: coerce expected a string, got integer.
#import "../../lib.typ": coerce, content-type, object
#coerce((a: 1), schema: object((a: content-type)))
