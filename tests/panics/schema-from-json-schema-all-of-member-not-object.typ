// expect: at /allOf/0: allOf members must all be object schemas, got: a string schema.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((allOf: ((type: "string"),)))
