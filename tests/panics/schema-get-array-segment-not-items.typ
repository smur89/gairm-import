// expect: schema-get path segment must be "items" for an array schema, got: "0".
#import "../../lib.typ": array-of, schema-get, object, string
#schema-get(object((xs: array-of(string()))), ("xs", "0"))
