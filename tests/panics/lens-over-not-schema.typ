// expect: lens-over result must be a schema; got: none.
// A function that forgets to return the node.
#import "../../lib.typ": lens, lens-over, object, str-type
#lens-over(lens(("a",)), object((a: str-type)), s => { let _ = s })
