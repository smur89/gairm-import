// expect: "$ref" must be a string, got: number.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("$ref": 1))
