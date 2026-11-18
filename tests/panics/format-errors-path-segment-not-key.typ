// expect: format-errors errors must be an array of error records, as validate returns them, got: ((path: ("items", true), message: "x"),).
// A path segment must be a key or an index.
#import "../../lib.typ": format-errors
#format-errors(((path: ("items", true), message: "x"),))
