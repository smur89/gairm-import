// expect: unset-required keys not in required-keys: a.
#import "../../lib.typ": lens, object, str-type, unset-required
#unset-required(object((a: str-type)), lens(()), ("a",))
