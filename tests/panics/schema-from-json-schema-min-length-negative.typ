// expect: "minLength" must be a non-negative integer
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", minLength: -1))
