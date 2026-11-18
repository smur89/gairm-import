// expect: got: an object schema.
// A whole node is named by its kind, not printed in full.
#import "../../lib.typ": paths-of-kind, object, string
#paths-of-kind(object((a: string())), object((b: string())))
