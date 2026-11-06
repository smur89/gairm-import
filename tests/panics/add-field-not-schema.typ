// expect: object() field "b" must be a schema; got: 1.
#import "../../lib.typ": add-field, lens, object, str-type
#add-field(object((a: str-type)), lens(()), "b", 1)
