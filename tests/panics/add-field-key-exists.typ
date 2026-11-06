// expect: add-field key "a" already in object shape.
#import "../../lib.typ": add-field, lens, object, str-type
#add-field(object((a: str-type)), lens(()), "a", str-type)
