// expect: object() required-keys references keys not in shape: b.
#import "../../lib.typ": object, string
#object((a: string()), required-keys: ("b",))
