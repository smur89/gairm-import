// expect: object() field "a" must be a schema, got: string. Call it: string().
#import "../../lib.typ": object, string
#object((a: string))
