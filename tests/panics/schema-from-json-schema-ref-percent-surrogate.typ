// expect: schema-from-json-schema — at the root: $ref "#/definitions/%ED%A0%80" has a malformed percent escape
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (a: (type: "string")),
  "$ref": "#/definitions/%ED%A0%80",
))
