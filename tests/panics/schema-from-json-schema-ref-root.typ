// expect: $ref "#/" cannot reference the document root.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("$ref": "#/"))
