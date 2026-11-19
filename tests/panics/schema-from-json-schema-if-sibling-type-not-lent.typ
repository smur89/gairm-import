// expect: at the root: the siblings of "if" and its branches must all be object schemas, got: a string schema.
#import "/lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "string",
  "if": (minLength: 2),
  then: (required: ("a",)),
))
