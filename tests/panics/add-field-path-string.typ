// expect: add-field path must be an array of path segments, got: "basics".
#import "../../lib.typ": add-field, object, string
#add-field(object((basics: object((:)))), "basics", "x", string())
