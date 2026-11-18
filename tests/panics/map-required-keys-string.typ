// expect: map() required-keys must be an array of key names, got: "a". Write ("a",) for one key.
#import "../../lib.typ": map, string
#map(string(), required-keys: "a")
