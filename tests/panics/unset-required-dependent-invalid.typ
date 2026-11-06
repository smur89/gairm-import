// expect: object() dependent-required references keys not in shape: x.
#import "../../lib.typ": lens, unset-required, str-type
#let bad = (
  kind: "object",
  shape: (a: str-type),
  required-keys: ("a",),
  dependent-required: (a: ("x",)),
)
#unset-required(bad, lens(()), ("a",))
