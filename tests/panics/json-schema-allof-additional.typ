// expect: allOf members declare conflicting additionalProperties
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((
  allOf: (
    (
      type: "object",
      properties: (a: (type: "string")),
      additionalProperties: true,
    ),
    (type: "object", properties: (b: (type: "string"))),
  ),
))
