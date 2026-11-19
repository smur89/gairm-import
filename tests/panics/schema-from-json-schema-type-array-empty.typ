// expect: must be a non-empty array of type names, got: [].
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: ()))
