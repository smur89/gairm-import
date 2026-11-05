// expect: cannot be combined with enum/const
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  "enum": ((a: 1),),
  dependentRequired: (a: ("b",)),
))
