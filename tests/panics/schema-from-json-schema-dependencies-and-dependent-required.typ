// expect: "dependencies" and "dependentRequired" cannot both be set
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  properties: (a: (:), b: (:)),
  dependencies: (a: ("b",)),
  dependentRequired: (a: ("b",)),
))
