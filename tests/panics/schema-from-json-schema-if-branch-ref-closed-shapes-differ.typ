// expect: at the root: the siblings of "if" and its branches with `additionalProperties: false` or a schema must all declare the same properties
// A branch that is a `$ref` to a nullable closed object restricts
// extras as its object does: draft 7 rejects `(kind: "x", b: "y")`.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (
    b: (
      anyOf: (
        (
          type: "object",
          properties: (b: (type: "string")),
          additionalProperties: false,
        ),
        (type: "null"),
      ),
    ),
  ),
  type: "object",
  properties: (kind: (type: "string")),
  "if": (required: ("kind",)),
  then: ("$ref": "#/definitions/b"),
))
