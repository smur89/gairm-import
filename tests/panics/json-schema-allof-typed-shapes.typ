// expect: allOf members with `additionalProperties: false` or a schema must all declare the same properties
#import "../../lib.typ": schema-from-json-schema
// Draft 7 rejects `(b: 1)`: the first member checks `b` against its
// additionalProperties string schema.
#schema-from-json-schema((
  allOf: (
    (
      type: "object",
      properties: (a: (type: "string")),
      additionalProperties: (type: "string"),
    ),
    (
      type: "object",
      properties: (b: (type: "number")),
      additionalProperties: (type: "string"),
    ),
  ),
))
