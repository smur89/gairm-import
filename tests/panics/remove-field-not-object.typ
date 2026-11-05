// expect: remove-field expects an object schema at the lens target
#import "../../lib.typ": lens, object, remove-field, str-type
#remove-field(object((a: str-type)), lens(("a",)), "k")
