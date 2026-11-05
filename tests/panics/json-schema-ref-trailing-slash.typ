// expect: $ref "#/definitions/foo/" could not be resolved (segment "" missing).
#import "../../lib.typ": schema-from-json-schema
// RFC 6901: the trailing empty segment is the "" key, which foo lacks.
#schema-from-json-schema((
  definitions: (foo: (type: "string")),
  "$ref": "#/definitions/foo/",
))
