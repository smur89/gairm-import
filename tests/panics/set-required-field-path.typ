// expect: set-required the node at ("a",) must be an object schema, got: a string schema. set-required takes the object's path: ().
#import "/lib.typ": set-required, object, string
#set-required(object((a: string())), ("a",), ("a",))
