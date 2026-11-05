// expect: allOf members declare conflicting schemas for key "a".
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((
  allOf: (
    (type: "object", properties: (a: (type: "string"))),
    (type: "object", properties: (a: (type: "number"))),
  ),
))
