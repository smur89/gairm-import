// expect: path segment must be "items" for an array schema, got: 0. A data path (an error record's) indexes elements; a schema path enters them all as "items".
#import "../../lib.typ": schema-get, object, array-of, string
#schema-get(object((work: array-of(object((url: string()))))), (
  "work",
  0,
  "url",
))
