// expect: schema-get path segment none not in object shape. Valid keys: additionalProperties.
// A none segment never reaches the shadowed additional schema.
#import "../../lib.typ": schema-get, object, string, number
#schema-get(object((additionalProperties: string()), additional: number()), (
  none,
))
