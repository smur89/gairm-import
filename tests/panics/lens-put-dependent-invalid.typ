// expect: object() dependent-required references keys not in shape: x.
// Closing an open object whose dependent-required names a key only
// the openness allowed.
#import "../../lib.typ": lens, lens-put, object, str-type
#let open = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#lens-put(lens(("o",)), object((o: open)), (..open, additional: none))
