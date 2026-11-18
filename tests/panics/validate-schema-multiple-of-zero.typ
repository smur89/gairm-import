// expect: gairm-import: multiple-of must be positive, got: 0.
#import "../../lib.typ": validate
#validate((kind: "number", multiple-of: 0), 4)
