// expect: lens-get takes a schema, then a location (a lens or a path array); got a dictionary and a location.
#import "../../lib.typ": lens-get
#lens-get((a: 1), ("a",))
