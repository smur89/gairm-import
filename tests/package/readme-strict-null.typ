// Mirrors README.md, "Strict null": the example and the result its
// comment shows. The asserts are ours.
#import "@preview/gairm-import:0.0.0": parse, object, str-type, nullable

#let schema = object(
  (name: str-type, nickname: nullable(str-type)),
  required-keys: ("name", "nickname"),
)
#assert.eq(
  parse((name: "Ada", nickname: none), schema: schema, strict-null: true),
  (name: "Ada", nickname: none),
)
