// expect: coerce at a: expected a value matching one of the union alternatives, got integer.
#import "../../lib.typ": any-of, bool-type, coerce, object, string
#coerce((a: 1), schema: object((a: any-of((string(), bool-type)))))
