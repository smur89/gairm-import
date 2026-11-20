// expect: validate schema field "integer" does nothing on a number schema. Drop it: integer() builds a whole number.
// 0.x's integral flag is refused, not ignored.
#import "../../lib.typ": validate
#validate((kind: "number", integer: true), 1.5)
