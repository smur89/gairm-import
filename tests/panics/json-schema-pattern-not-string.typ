// expect: "pattern" must be a regex or a string, got: integer.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", pattern: 1))
