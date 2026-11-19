// expect: set-required the node at ("a",) must be an object schema, got: a union schema. Insert 0 to step into nullable(object).
#import "../../lib.typ": set-required, object, nullable, string
#set-required(object((a: nullable(object((b: string()))))), ("a",), ("b",))
