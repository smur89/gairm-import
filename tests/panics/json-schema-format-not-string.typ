// expect: "format" must be a string, got: int.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", format: 5))
