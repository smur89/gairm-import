// expect: array-of() elem must be a schema; got: (kind: "bogus").
#import "../../lib.typ": array-of
#array-of((kind: "bogus"))
