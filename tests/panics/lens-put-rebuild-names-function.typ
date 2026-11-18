// expect: lens-put required-keys references keys not in shape: zz.
// An object rebuilt on the way back up names the lens function.
#import "../../lib.typ": lens-put, string, integer
#let s = (
  kind: "object",
  shape: (a: (kind: "object", shape: (b: string()), required-keys: ("zz",))),
  required-keys: (),
)
#lens-put(s, ("a", "b"), integer())
