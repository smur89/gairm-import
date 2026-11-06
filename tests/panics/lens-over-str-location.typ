// expect: lens-over takes a schema, then a location (a lens or a path array); got a schema and a string.
#import "../../lib.typ": lens-over, object, str-type
#lens-over(object((a: str-type)), "a", n => n)
