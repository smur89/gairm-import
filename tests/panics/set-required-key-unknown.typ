// expect: set-required keys not in object shape: b.
#import "../../lib.typ": lens, object, set-required, str-type
#set-required(object((a: str-type)), lens(()), ("b",))
