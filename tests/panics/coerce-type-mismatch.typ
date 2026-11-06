// expect: gairm-import: coerce at <root>: expected a string, got integer. Run validate(data) first.
#import "../../lib.typ": coerce, str-type
#coerce(1, schema: str-type)
