// expect: "anyOf" must be a non-empty array of schemas
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((anyOf: ()))
