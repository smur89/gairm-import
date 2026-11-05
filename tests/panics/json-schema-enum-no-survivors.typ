// expect: no enum/const value satisfies
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("enum": (1, 2), minimum: 5))
