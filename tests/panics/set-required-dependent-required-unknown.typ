// expect: set-required dependent-required references keys not in shape: x.
#import "../../lib.typ": set-required, string
#let bad = (
  kind: "object",
  shape: (a: string()),
  required-keys: (),
  dependent-required: (x: ("a",)),
)
#set-required(bad, (lens: ()), ("a",))
