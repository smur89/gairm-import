// expect: coerce at a: expected a value matching one of the union alternatives, got integer.
#import "../../lib.typ": any-of, bool-type, coerce, object, str-type
#coerce((a: 1), schema: object((a: any-of((str-type, bool-type)))))
