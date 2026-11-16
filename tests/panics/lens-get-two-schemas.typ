// expect: lens-get takes a schema, then a location (a lens or a path array); got a schema and a schema.
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), string())
