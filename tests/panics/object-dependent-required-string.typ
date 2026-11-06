// expect: object() dependent-required for "a" must be an array of key names
#import "../../lib.typ": object, str-type
#object((a: str-type), dependent-required: (a: "b"))
