// expect: "multipleOf" must be > 0
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "number", multipleOf: 0))
