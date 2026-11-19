// expect: "properties" must be an object, got: 1.
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((type: "object", properties: 1))
