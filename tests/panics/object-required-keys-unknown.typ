// expect: object() required-keys references keys not in shape: b.
#import "../../lib.typ": object, str-type
#object((a: str-type), required-keys: ("b",))
