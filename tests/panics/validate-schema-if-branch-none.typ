// expect: validate schema field "then" must be a schema, got: none. Leave the field out to unset it.
#import "/lib.typ": validate, string
#validate((kind: "if", cond: string(), then: none, otherwise: string()), 1)
