// expect: coerce at <root>: expected one of "a", "b", got "c". Run
// The value, not its type: a string is what the enum takes.
#import "../../lib.typ": coerce, enum-of
#coerce(enum-of(("a", "b")), "c")
