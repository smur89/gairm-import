// expect: the siblings of "if" and its branches must all be object schemas; got kind "string". Non-object composition is out of scope: move the sibling keywords into "then" and "else".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "string",
  "if": (minLength: 5),
  then: (pattern: "^x"),
))
