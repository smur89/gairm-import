// expect: validate schema field "format" must be a format name, got: none. Leave the field out to unset it.
#import "../../lib.typ": validate
#validate((kind: "string", format: none), "x")
