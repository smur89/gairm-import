// expect: "pattern" must be a string, got: 1.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", pattern: 1))
