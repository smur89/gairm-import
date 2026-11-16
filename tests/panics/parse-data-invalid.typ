// expect: found 1 problem in the input:
#import "../../lib.typ": parse, object, string
#parse((name: 1), schema: object((name: string())))
