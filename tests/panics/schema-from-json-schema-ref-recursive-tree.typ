// expect: recursive $ref: "#/definitions/node" → "#/definitions/node" refers back to itself. A translated schema is a finite tree
// A legitimate recursive schema (a tree of nodes) is named as such, not
// as a broken cycle.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  "$ref": "#/definitions/node",
  definitions: (
    node: (
      type: "object",
      properties: (
        children: (type: "array", items: ("$ref": "#/definitions/node")),
      ),
    ),
  ),
))
