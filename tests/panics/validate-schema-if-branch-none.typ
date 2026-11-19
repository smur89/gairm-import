// expect: field "then" must be a schema, got: none. Leave the field out for no branch.
#import "/lib.typ": validate, string
#validate((kind: "if", cond: string(), then: none, otherwise: string()), 1)
