// expect: "enum" must be an array of values, got: number.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("enum": 1))
