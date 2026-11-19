// expect: unset-required keys not in required-keys: a. Current required: b.
#import "../../lib.typ": object, unset-required, string
#unset-required(object((a: string(), b: string()), required-keys: ("b",)), (), ("a",))
