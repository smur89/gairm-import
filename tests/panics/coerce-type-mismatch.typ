// expect: gairm-import: coerce at <root>: expected a string, got integer. Run validate(data) first.
#import "../../lib.typ": coerce, string
#coerce(string(), 1)
