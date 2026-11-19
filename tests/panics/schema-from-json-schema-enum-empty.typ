// expect: "enum" must be a non-empty array of values, got: [].
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((enum: ()))
