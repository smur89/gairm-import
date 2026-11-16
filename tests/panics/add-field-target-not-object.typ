// expect: add-field expects an object schema at the lens target
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), (lens: ("a",)), "k", string())
