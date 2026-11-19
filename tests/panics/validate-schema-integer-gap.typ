// expect: validate schema field "minimum" (1.5) and field "maximum" (1.7) leave no integer.
#import "../../lib.typ": validate
#validate((kind: "integer", minimum: 1.5, maximum: 1.7), 2)
