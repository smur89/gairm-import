// expect: recursive $ref: "#/definitions/a" → "#/definitions/%61" refers back to itself.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (a: ("$ref": "#/definitions/%61")),
  "$ref": "#/definitions/a",
))
