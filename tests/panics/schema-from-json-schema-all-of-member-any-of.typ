// expect: at /allOf/0: allOf members must all be object schemas, got one with "anyOf".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  allOf: ((anyOf: ((type: "string"), (type: "number"))),),
))
