// expect: could not be resolved
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("$ref": "#/definitions/missing", definitions: (:)))
