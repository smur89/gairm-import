// expect: schema-from-json-schema — a subschema must be a schema object, got: 1.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("not": 1))
