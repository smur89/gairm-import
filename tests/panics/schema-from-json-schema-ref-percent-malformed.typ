// expect: schema-from-json-schema — at the root: $ref "#/definitions/a%2" has a malformed percent escape
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: ("a%2": (type: "string")),
  "$ref": "#/definitions/a%2",
))
