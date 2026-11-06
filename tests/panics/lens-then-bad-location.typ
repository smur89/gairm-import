// expect: lens-then location must be a lens or a path array; got: "name".
#import "../../lib.typ": lens, lens-then
#lens-then(lens(("basics",)), "name")
