// expect: allOf members must all be object schemas
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((allOf: ((type: "string"),)))
