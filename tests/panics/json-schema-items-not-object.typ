// expect: "items" must be a schema object
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "array", items: 1))
