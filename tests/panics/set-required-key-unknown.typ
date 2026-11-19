// expect: set-required keys not in object shape: b.
#import "../../lib.typ": object, set-required, string
#set-required(object((a: string())), (), ("b",))
