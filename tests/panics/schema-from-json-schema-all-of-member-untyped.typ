// expect: at /allOf/1: allOf members must all be object schemas, got one with no "type": "object" or "properties", only "required". Non-object composition is out of scope.
// An untyped member takes any JSON type; it is named by what it lacks,
// not by the union it translates to.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  allOf: (
    (type: "object", properties: (a: (type: "string"))),
    (required: ("a",)),
  ),
))
