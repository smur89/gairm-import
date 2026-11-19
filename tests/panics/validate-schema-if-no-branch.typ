// expect: validate schema needs a then or an otherwise branch; got neither.
// Hand-built: a conditional if-of() would refuse fails up front.
#import "../../lib.typ": validate, string
#validate((kind: "if", cond: string()), "x")
