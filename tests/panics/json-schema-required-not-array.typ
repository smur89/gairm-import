// expect: "required" must be an array of key names
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((type: "object", properties: (:), required: "a"))
