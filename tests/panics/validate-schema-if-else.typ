// expect: field "else" does nothing on an if schema. The else branch is the field otherwise.
#import "../../lib.typ": validate, string, number
#validate((kind: "if", cond: string(), then: number(), "else": number()), 1)
