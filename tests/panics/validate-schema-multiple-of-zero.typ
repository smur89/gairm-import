// expect: gairm-import: validate schema field "multiple-of" must be > 0, got: 0.
#import "../../lib.typ": validate
#validate((kind: "number", multiple-of: 0), 4)
