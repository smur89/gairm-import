// expect: are only supported as nullable wraps
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: ("string", "number")))
