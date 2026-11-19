// expect: object() required-keys must be only declared fields (the object takes no other keys), got: "b".
#import "../../lib.typ": object, string
#object((a: string()), required-keys: ("b",))
