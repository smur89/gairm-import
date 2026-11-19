// expect: unset-required keys not in required-keys: a. Current required: none.
// A hand-built object with no `required-keys` requires nothing.
#import "../../lib.typ": string, unset-required
#unset-required((kind: "object", shape: (a: string())), (), ("a",))
