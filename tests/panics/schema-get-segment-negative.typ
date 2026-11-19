// expect: schema-get path segment -1 not in object shape. Valid keys: "-1".
// Only a non-negative int names the field it spells, as a JSON Pointer
// reads one.
#import "../../lib.typ": schema-get, object, string
#schema-get(object(("-1": string())), (-1,))
