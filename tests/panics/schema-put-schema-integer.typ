// expect: schema-put schema must be a schema, got: 5. Build schemas with the constructors.
// Given a path second, the first argument is checked as a schema.
#import "../../lib.typ": schema-put, string
#schema-put(5, ("a",), string())
