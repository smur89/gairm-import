// expect: coerce at a: expected a value matching one of the union alternatives, got integer.
#import "../../lib.typ": any-of, boolean, coerce, object, string
#coerce(object((a: any-of((string(), boolean())))), (a: 1))
