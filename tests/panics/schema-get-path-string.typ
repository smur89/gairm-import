// expect: schema-get path must be an array of path segments, got: "a". Write ("a",) for one key.
#import "../../lib.typ": schema-get, object, string
#schema-get(object((a: string())), "a")
