// expect: gairm-import: coerce at <root>: expected a string, got integer. Run validate(schema, data) first.
#import "../../lib.typ": coerce, string
#coerce(string(), 1)
