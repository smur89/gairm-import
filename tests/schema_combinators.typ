// Schema combinators produce dispatchable type nodes.

#import "../internal/schema.typ": str-type, content-type, number-type, array-of, object

#assert.eq(str-type, (kind: "str"))
#assert.eq(content-type, (kind: "content"))
#assert.eq(number-type, (kind: "number"))
#assert.eq(array-of(str-type), (kind: "array", elem: (kind: "str")))
#assert.eq(
  object((name: str-type, age: number-type)),
  (kind: "object", shape: (name: (kind: "str"), age: (kind: "number"))),
)
