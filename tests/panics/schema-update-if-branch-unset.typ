// expect: got: "else". To set it, schema-update the if-of: n => (..n, otherwise: value).
#import "../../lib.typ": schema-update, if-of, string
#schema-update(if-of(string(), then: string(min-length: 1)), ("else",), n => n)
