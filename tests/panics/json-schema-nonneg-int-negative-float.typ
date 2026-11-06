// expect: "minLength" must be a non-negative integer, got: -1.0.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", minLength: -1.0))
