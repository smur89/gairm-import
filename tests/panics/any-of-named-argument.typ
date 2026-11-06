// expect: any-of() takes no named arguments; got: (exclusive: true).
#import "../../lib.typ": any-of, str-type, number-type
#any-of(str-type, number-type, exclusive: true)
