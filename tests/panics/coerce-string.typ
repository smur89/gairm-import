// expect: coerce at a: expected a string, got integer. Run validate(data) first.
#import "../../lib.typ": coerce, object, str-type
#coerce((a: 1), schema: object((a: str-type)))
