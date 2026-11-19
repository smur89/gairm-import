// expect: coerce at <root>: expected a value matching one of the union alternatives, got "c".
// Both members take strings, so the value is named, not its type.
#import "../../lib.typ": coerce, any-of, enum-of, string
#coerce(any-of(enum-of(("a",)), string(pattern: "^x", max-length: 0)), "c")
