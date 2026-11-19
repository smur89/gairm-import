// expect: schema-put path segment "b" not in object shape.
// A bad segment names the function that followed the path.
#import "../../lib.typ": schema-put, object, string
#schema-put(object((a: string())), ("b",), string())
