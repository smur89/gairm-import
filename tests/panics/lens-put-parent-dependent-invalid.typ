// expect: object() dependent-required references keys not in shape: x.
// A hand-built parent whose dependent-required names a missing key:
// writing one of its fields rebuilds it through object().
#import "../../lib.typ": lens, lens-put, str-type
#let bad = (
  kind: "object",
  shape: (a: str-type),
  required-keys: (),
  dependent-required: (a: ("x",)),
)
#lens-put(lens(("a",)), bad, str-type)
