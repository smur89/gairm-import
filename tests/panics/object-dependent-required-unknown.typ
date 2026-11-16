// expect: object() dependent-required references keys not in shape: missing.
#import "../../lib.typ": object, string
#object((a: string()), dependent-required: (a: ("missing",)))
