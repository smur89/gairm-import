// expect: object() dependent-required references keys not in shape: x.
#import "../../lib.typ": add-field, lens, str-type
#let bad = (
  kind: "object",
  shape: (a: str-type),
  required-keys: (),
  dependent-required: (a: ("x",)),
)
#add-field(bad, lens(()), "b", str-type)
