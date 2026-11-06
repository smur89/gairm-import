// expect: lens segment for an if schema must be one of "if", "then", got "else".
#import "../../lib.typ": lens-get, if-of, string
#lens-get(if-of(string(), then: string(min-length: 1)), ("else",))
