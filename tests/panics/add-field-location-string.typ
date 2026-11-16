// expect: add-field location must be a lens or a path array, got: "basics".
#import "../../lib.typ": add-field, object, string
#add-field(object((basics: object((:)))), "basics", "x", string())
