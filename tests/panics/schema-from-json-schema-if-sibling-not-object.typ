// expect: the siblings of "if" and its branches must all be object schemas, got: a string schema. Non-object composition is out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "string",
  "if": (minLength: 5),
  then: (pattern: "^x"),
))
