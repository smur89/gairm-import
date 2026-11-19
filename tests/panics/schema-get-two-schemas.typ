// expect: schema-get path must be an array of path segments, got: a schema.
// A schema in the path's place is named, not printed whole.
#import "../../lib.typ": schema-get, object, string
#schema-get(object((a: string())), string())
