// expect: lens-get path segment must be one of "if", "then" for an if schema, got: "else".
#import "../../lib.typ": lens-get, if-of, string
#lens-get(if-of(string(), then: string(min-length: 1)), ("else",))
