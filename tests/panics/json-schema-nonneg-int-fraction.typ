// expect: "maxItems" must be a non-negative integer, got: 2.5.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "array",
  items: (type: "string"),
  maxItems: 2.5,
))
