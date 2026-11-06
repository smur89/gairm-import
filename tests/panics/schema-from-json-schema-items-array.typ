// expect: the array form of "items" (one schema per position). Tuple validation is out of scope
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "array",
  items: ((type: "string"), (type: "number")),
))
