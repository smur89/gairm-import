// expect: object() dependent-required must be only declared fields (the object takes no other keys), got: "missing".
#import "../../lib.typ": object, string
#object((a: string()), dependent-required: (a: ("missing",)))
