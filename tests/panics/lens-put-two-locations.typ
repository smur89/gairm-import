// expect: lens-put takes a schema, then a location (a lens or a path array); got a location and a location.
#import "../../lib.typ": lens, lens-put, str-type
#lens-put(lens(("a",)), ("b",), str-type)
