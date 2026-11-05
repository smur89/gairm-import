// expect: cannot be combined with enum/const
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("enum": ("a",), minLength: 1))
