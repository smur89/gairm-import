// expect: "$ref" must be a string
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("$ref": 1))
