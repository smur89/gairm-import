// expect: allOf members with `additionalProperties: false` or a schema must all declare the same properties
#import "../../lib.typ": schema-from-json-schema
// Draft 7 rejects `(a: "x")`: the second member's additionalProperties
// rejects `a`.
#schema-from-json-schema((
  allOf: (
    (
      type: "object",
      properties: (a: (type: "string")),
      additionalProperties: false,
    ),
    (
      type: "object",
      properties: (b: (type: "string")),
      additionalProperties: false,
    ),
  ),
))
