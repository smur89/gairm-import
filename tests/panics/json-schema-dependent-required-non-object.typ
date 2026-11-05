// expect: are only supported on `type: "object"` schemas
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", dependentRequired: (a: ("b",))))
