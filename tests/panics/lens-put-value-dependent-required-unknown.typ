// expect: object() dependent-required references keys not in shape: x.
// Closing an open object whose dependent-required names a key only
// the openness allowed.
#import "../../lib.typ": lens-put, object, string
#let open = object(
  (a: string()),
  dependent-required: (a: ("x",)),
  additional: true,
)
#lens-put(object((o: open)), ("o",), (..open, additional: none))
