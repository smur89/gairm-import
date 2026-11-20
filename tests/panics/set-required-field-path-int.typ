// expect: set-required the node at (2024,) must be an object schema, got: a string schema. set-required takes the object's path: ().
#import "../../lib.typ": set-required, object, string
#set-required(object(("2024": string())), (2024,), ("a",))
