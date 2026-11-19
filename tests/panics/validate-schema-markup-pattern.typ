// expect: validate schema field "pattern" does nothing on markup, which takes no pattern or format; use string() for one.
#import "../../lib.typ": validate
#validate((kind: "markup", pattern: regex("^x")), "y")
