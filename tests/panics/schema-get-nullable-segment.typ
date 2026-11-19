// expect: schema-get path segment must be a member index, 0 to 1, for a union schema, got: "b". Insert 0 to step into nullable(object).
// A nullable is a union: its schema is member 0, not the next segment.
#import "../../lib.typ": schema-get, object, nullable, string
#schema-get(object((a: nullable(object((b: string()))))), ("a", "b"))
