// expect: found 1 problem in the input:
#import "../../lib.typ": parse, object, string
#parse(object((name: string())), (name: 1))
