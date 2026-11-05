// expect: "oneOf" members must be schema objects
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((oneOf: (1,)))
