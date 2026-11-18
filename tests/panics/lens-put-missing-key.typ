// expect: lens-put path segment "b" not in object shape.
// A bad segment names the function that followed the path.
#import "../../lib.typ": lens-put, object, string
#lens-put(object((a: string())), ("b",), string())
