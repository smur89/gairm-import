// expect: exclusiveMinimum (5) and maximum (5) leave no satisfying value.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "number", exclusiveMinimum: 5, maximum: 5))
