// expect: object() required-keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": object, string
#object((a: string()), required-keys: "a")
