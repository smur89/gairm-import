// expect: parse takes the schema first, then the data: parse(schema, data).
#import "../../lib.typ": parse, object, string
#parse((a: "x"), object((a: string())))
