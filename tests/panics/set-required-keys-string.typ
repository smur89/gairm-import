// expect: set-required keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": object, set-required, string
#set-required(object((a: string())), (), "a")
