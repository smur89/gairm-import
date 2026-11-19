// expect: set-required dependent-required must be only declared fields (the object takes no other keys), got: "x".
#import "../../lib.typ": set-required, string
#let bad = (
  kind: "object",
  shape: (a: string()),
  required-keys: (),
  dependent-required: (x: ("a",)),
)
#set-required(bad, (), ("a",))
