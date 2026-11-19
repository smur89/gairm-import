// expect: validate schema field "minimum" (5) > field "maximum" (1) is unsatisfiable.
// A hand-built node meets number()'s rules too.
#import "../../lib.typ": validate
#validate((kind: "number", minimum: 5, maximum: 1), 3)
