// expect: schema-from-json-schema — "required" names keys not in "properties" of an object that takes no other keys: a.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "object", properties: (:), required: ("a",)))
