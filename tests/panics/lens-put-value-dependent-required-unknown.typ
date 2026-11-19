// expect: lens-put value dependent-required must be only declared fields (the object takes no other keys), got: "x".
// Closing an open object whose dependent-required names a key only
// the openness allowed.
#import "../../lib.typ": lens-put, object, string
#let open = object(
  (a: string()),
  dependent-required: (a: ("x",)),
  additional: true,
)
#lens-put(object((o: open)), ("o",), (..open, additional: none))
