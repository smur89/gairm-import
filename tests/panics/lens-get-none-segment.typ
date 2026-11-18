// expect: lens-get path segment none not in object shape. Valid keys: additionalProperties.
// A none segment never reaches the shadowed additional schema.
#import "../../lib.typ": lens-get, object, string, number
#lens-get(object((additionalProperties: string()), additional: number()), (
  none,
))
