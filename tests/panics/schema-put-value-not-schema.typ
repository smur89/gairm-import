// expect: schema-put value must be a schema, got: 1. Build schemas with the constructors.
#import "../../lib.typ": schema-put, object, string
#schema-put(object((a: string())), ("a",), 1)
