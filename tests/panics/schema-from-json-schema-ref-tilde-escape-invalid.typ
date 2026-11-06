// expect: schema-from-json-schema — $ref "#/definitions/a~2b" has an invalid escape
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: ("a~2b": (type: "string")),
  "$ref": "#/definitions/a~2b",
))
