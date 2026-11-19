// expect: schema-from-json-schema — at the root: "type" must not be null.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: none))
