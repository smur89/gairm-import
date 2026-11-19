// expect: lens-get takes a schema, then a path (an array of segments); got a schema and a schema.
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), string())
