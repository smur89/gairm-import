// expect: gairm-import: multiple-of must be positive, got 0.
#import "../../lib.typ": validate
#validate(4, schema: (kind: "number", multiple-of: 0))
