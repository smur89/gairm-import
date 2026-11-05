// expect: "not" must be a schema object
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("not": 1))
