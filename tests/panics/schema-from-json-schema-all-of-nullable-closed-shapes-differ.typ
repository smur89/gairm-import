// expect: at the root: allOf members with `additionalProperties: false` or a schema must all declare the same properties
// A nullable closed object, written as an anyOf with null, restricts
// extras as its object does: draft 7 rejects `(a: "x", b: "y")`.
#import "../../lib.typ": schema-from-json-schema
#let closed(key) = (
  anyOf: (
    (
      type: "object",
      properties: ((key): (type: "string")),
      additionalProperties: false,
    ),
    (type: "null"),
  ),
)
#schema-from-json-schema((allOf: (closed("a"), closed("b"))))
