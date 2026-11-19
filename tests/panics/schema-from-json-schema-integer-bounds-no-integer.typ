// expect: schema-from-json-schema — at the root: exclusiveMinimum (1) and exclusiveMaximum (2) leave no integer.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "integer",
  exclusiveMinimum: 1,
  exclusiveMaximum: 2,
))
