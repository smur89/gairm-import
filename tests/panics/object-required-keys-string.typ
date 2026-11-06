// expect: object() required-keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": object, str-type
#object((a: str-type), required-keys: "a")
