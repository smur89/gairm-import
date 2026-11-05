// expect: only internal $ref (starting with "#/") is supported
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("$ref": "other.json"))
