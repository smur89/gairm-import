// expect: unset-required keys not in required-keys: a.
#import "../../lib.typ": object, unset-required, string
#unset-required(object((a: string())), (lens: ()), ("a",))
