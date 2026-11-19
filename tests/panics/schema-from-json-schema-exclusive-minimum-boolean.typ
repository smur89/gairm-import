// expect: at the root: "exclusiveMinimum" must be a number, got: true. Draft 4's boolean form is not supported
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "number", minimum: 5, exclusiveMinimum: true))
