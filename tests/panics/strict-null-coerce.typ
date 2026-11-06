// expect: coerce at name: expected a string, got null.
#import "../../lib.typ": coerce, object, str-type
#coerce((name: none), schema: object((name: str-type)), strict-null: true)
