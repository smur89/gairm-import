// expect: "minLength" must be a non-negative integer, got: 1e20.
// A whole float too large for an int is refused, not overflowed.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", minLength: 1e20))
