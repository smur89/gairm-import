// expect: input must be a dict, got null.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(bytes("null"))
