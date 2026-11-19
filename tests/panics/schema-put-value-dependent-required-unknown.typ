// expect: schema-put value field "dependent-required" must be only declared fields (the object takes no other keys), got: "x".
// Closing an open object whose dependent-required names a key only
// the openness allowed.
#import "../../lib.typ": schema-put, object, string
#let open = object(
  (a: string()),
  dependent-required: (a: ("x",)),
  additional: true,
)
#schema-put(object((o: open)), ("o",), (..open, additional: none))
