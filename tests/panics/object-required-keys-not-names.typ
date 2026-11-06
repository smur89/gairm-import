// expect: object() required-keys must be an array of key names; got: ("a", 1).
#import "../../lib.typ": object, str-type
#object((a: str-type), required-keys: ("a", 1), additional: true)
