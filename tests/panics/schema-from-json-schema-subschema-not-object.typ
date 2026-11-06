// expect: a subschema must be a schema object, got: 1.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (one: 1),
  "$ref": "#/definitions/one",
))
