// expect: unset-required keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": object, unset-required, string
#unset-required(object((a: string()), required-keys: ("a",)), (), "a")
