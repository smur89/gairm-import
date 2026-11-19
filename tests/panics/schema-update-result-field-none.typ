// expect: schema-update result field "minimum" must be a number, got: none. Leave the field out to unset it.
#import "../../lib.typ": schema-update, object, number
#schema-update(object((n: number(minimum: 1))), ("n",), n => (
  ..n,
  minimum: none,
))
