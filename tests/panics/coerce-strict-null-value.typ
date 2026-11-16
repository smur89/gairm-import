// expect: coerce at name: expected a string, got null.
#import "../../lib.typ": coerce, object, string
#coerce((name: none), schema: object((name: string())), strict-null: true)
