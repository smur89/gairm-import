// expect: object() dependent-required references keys not in shape: x.
#import "../../lib.typ": lens, lens-over, object, str-type
#let open = object(
  (a: str-type),
  dependent-required: (a: ("x",)),
  additional: true,
)
#lens-over(lens(("o",)), object((o: open)), o => (..o, additional: none))
