// expect: validate schema field "min-length" does nothing on an array schema.
// A field another kind reads would be ignored here, so it is refused.
#import "../../lib.typ": validate, string
#validate((kind: "array", elem: string(), min-length: 2), ())
