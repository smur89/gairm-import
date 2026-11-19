// expect: coerce at <root>: expected a value matching one of the union alternatives, got "c".
// Both members take strings and neither leaves a model, so the value is
// named, not its type.
#import "../../lib.typ": coerce, any-of, enum-of
#coerce(any-of(enum-of("a"), enum-of("b")), "c")
