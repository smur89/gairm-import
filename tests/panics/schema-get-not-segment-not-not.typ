// expect: schema-get path segment must be "not" for a not schema, got: 0.
#import "../../lib.typ": schema-get, not-of, object, string
#schema-get(object((a: not-of(string()))), ("a", 0))
