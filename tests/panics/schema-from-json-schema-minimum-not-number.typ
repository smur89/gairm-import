// expect: "minimum" must be a number
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "number", minimum: "a"))
