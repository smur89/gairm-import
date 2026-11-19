// expect: schema-get takes a schema, then a path (an array of segments); got a path and a schema.
#import "../../lib.typ": schema-get, object, string
#schema-get(("a",), object((a: string())))
