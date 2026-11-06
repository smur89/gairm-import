// expect: "uniqueItems" must be a boolean
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "array",
  items: (type: "string"),
  uniqueItems: 1,
))
