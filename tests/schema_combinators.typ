// Schema combinators produce dispatchable type nodes.

#import "../internal/kinds.typ": str-type, content-type, number-type, array-of, object

#assert.eq(str-type, (kind: "str"))
#assert.eq(content-type, (kind: "content"))
#assert.eq(number-type, (kind: "number"))
#assert.eq(array-of(str-type), (kind: "array", elem: (kind: "str")))
#assert.eq(
  object((name: str-type, age: number-type)),
  (
    kind: "object",
    shape: (name: (kind: "str"), age: (kind: "number")),
    required-keys: (),
  ),
)
#assert.eq(
  object((name: str-type), required-keys: ("name",)),
  (kind: "object", shape: (name: (kind: "str")), required-keys: ("name",)),
)

// Multiple required keys, all present in shape.
#assert.eq(
  object((a: str-type, b: str-type), required-keys: ("a", "b")).required-keys,
  ("a", "b"),
)
