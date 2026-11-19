// expect: enum-of() values must be a non-empty array, got: ().
// An empty enum would reject every value.
#import "../../lib.typ": enum-of
#enum-of(())
