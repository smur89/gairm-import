// expect: remove-field key "b" not in object shape.
#import "../../lib.typ": lens, object, remove-field, str-type
#remove-field(object((a: str-type)), lens(()), "b")
