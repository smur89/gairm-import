// expect: recursive $ref: "#/definitions/a" → "#/definitions/a" refers back to itself.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  "$ref": "#/definitions/a",
  definitions: (a: ("$ref": "#/definitions/a")),
))
