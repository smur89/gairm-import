// expect: add-field required must be true or false, got: "yes".
#import "../../lib.typ": add-field, object, str-type
#add-field(object((a: str-type)), (), "b", str-type, required: "yes")
