// expect: schema-put schema at ("a",) field "required-keys" must be only declared fields (the object takes no other keys), got: "zz".
// A hand-built closed object requiring a key it does not declare fails
// the schema check, as object() would refuse it, with its path.
#import "../../lib.typ": schema-put, string, integer
#let s = (
  kind: "object",
  shape: (a: (kind: "object", shape: (b: string()), required-keys: ("zz",))),
  required-keys: (),
)
#schema-put(s, ("a", "b"), integer())
