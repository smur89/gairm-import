// expect: validate schema field "pattern" does nothing on a markup schema. Use string() for one.
#import "../../lib.typ": validate
#validate((kind: "markup", pattern: regex("^x")), "y")
