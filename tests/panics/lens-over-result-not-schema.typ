// expect: lens-over result must be a schema; got: none.
// A function that forgets to return the node.
#import "../../lib.typ": lens-over, object, str-type
#lens-over(object((a: str-type)), ("a",), s => { let _ = s })
