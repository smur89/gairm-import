// expect: schema-from-json-schema — at the root: "required" must be only declared fields (the object takes no other keys), got: "a".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "object", properties: (:), required: ("a",)))
