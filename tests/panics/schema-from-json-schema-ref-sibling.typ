// expect: sibling keywords beside "$ref" are not supported
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (x: (type: "string")),
  "$ref": "#/definitions/x",
  minLength: 2,
))
