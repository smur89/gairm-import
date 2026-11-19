// expect: at /definitions/b: an embedded "$id" ("other.json") is not supported
// It would change the base of the $refs below it, which resolve against
// the root here.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (b: ("$id": "other.json", type: "string")),
  "$ref": "#/definitions/b",
))
