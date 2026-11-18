// expect: coerce at name: expected a string, got null.
#import "../../lib.typ": coerce, object, string
#coerce(object((name: string())), (name: none), strict-null: true)
