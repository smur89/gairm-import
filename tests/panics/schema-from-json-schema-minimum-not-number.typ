// expect: at the root: "minimum" must be a number, got: "a".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "number", minimum: "a"))
