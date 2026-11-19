// expect: got: an object schema.
// A whole node is named by its kind, not printed in full.
#import "../../lib.typ": find-paths, object, string
#find-paths(object((a: string())), object((b: string())))
