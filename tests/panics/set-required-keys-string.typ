// expect: set-required keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": object, set-required, str-type
#set-required(object((a: str-type)), (), "a")
