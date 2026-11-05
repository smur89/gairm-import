// expect: object() dependent-required references keys not in shape: missing.
#import "../../lib.typ": object, str-type
#object((a: str-type), dependent-required: (a: ("missing",)))
