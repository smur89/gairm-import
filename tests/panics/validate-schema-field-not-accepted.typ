// expect: validate schema field "min-length" must be a non-negative integer, got: "3".
// Hand-built: a constraint field is checked against its row.
#import "../../lib.typ": validate
#validate((kind: "string", min-length: "3"), "ab")
