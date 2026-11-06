// expect: schema-from-json-schema — $ref "#/definitions/%E0%80%80" has a malformed percent escape
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: ("\u{0}": (type: "string")),
  "$ref": "#/definitions/%E0%80%80",
))
