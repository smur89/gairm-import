// expect: add-field expects an object schema at the lens target
#import "../../lib.typ": add-field, lens, object, str-type
#add-field(object((a: str-type)), lens(("a",)), "k", str-type)
