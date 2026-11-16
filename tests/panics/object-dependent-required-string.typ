// expect: object() dependent-required for "a" must be an array of key names
#import "../../lib.typ": object, string
#object((a: string()), dependent-required: (a: "b"))
