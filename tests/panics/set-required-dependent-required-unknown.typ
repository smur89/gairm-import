// expect: object() dependent-required references keys not in shape: x.
#import "../../lib.typ": lens, set-required, str-type
#let bad = (
  kind: "object",
  shape: (a: str-type),
  required-keys: (),
  dependent-required: (x: ("a",)),
)
#set-required(bad, lens(()), ("a",))
