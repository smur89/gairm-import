// expect: schema-get path segment must be one of "if", "then" for an if schema, got: "else".
#import "../../lib.typ": schema-get, if-of, string
#schema-get(if-of(string(), then: string(min-length: 1)), ("else",))
