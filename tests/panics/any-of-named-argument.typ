// expect: any-of() takes no named arguments; got: (exclusive: true).
#import "../../lib.typ": any-of, string, number
#any-of(string(), number(), exclusive: true)
