// expect: at /properties/x: $ref "#foo" names an anchor, which is out of scope; reference the schema by its JSON Pointer ("#/definitions/…").
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (foo: ("$id": "#foo", type: "string")),
  type: "object",
  properties: (x: ("$ref": "#foo")),
))
