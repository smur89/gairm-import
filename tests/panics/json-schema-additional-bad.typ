// expect: "additionalProperties" must be a schema, true, or false
#import "../../lib.typ": object, schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (:),
  additionalProperties: 1,
))
