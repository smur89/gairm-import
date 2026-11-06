// expect: lens segment for a union schema must be a member index, 0 to 1, got "0".
#import "../../lib.typ": lens, lens-put, number-type, object, one-of, str-type
#lens-put(
  lens(("a", "0")),
  object((a: one-of((str-type, number-type)))),
  str-type,
)
