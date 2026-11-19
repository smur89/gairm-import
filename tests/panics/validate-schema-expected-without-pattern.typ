// expect: validate schema field "expected" must be given with a pattern, which it describes, got: "x".
#import "/lib.typ": validate
#validate((kind: "string", expected: "x"), "a")
