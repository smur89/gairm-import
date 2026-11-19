// expect: "properties" must be an object, got: number.
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((type: "object", properties: 1))
