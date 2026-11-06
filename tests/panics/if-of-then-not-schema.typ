// expect: if-of() then must be a schema; got: "x".
#import "../../lib.typ": if-of, string
#if-of(string(), then: "x")
