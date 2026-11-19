// expect: add-field required must be true or false, got: "yes".
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), ("b",), string(), required: "yes")
