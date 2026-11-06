// expect: add-field location must be a lens or a path array; got: "a".
#import "../../lib.typ": add-field, object, str-type
#add-field(object((a: object((:)))), "a", "b", str-type)
