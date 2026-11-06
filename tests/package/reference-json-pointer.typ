// Mirrors REFERENCE.md, "JSON Pointer": each call and the result its
// comment or text shows. The asserts are ours.
#import "@preview/gairm-import:0.0.0": path-to-pointer, pointer-to-path

#assert.eq(path-to-pointer(("basics", "email")), "/basics/email")
#assert.eq(
  path-to-pointer(("work", 0, "highlights", 1)),
  "/work/0/highlights/1",
)
#assert.eq(path-to-pointer(("a/b",)), "/a~1b")
#assert.eq(path-to-pointer(("~tilde",)), "/~0tilde")

#assert.eq(pointer-to-path("/work/0/highlights/1"), (
  "work",
  0,
  "highlights",
  1,
))
#assert.eq(pointer-to-path(""), ())
#assert.eq(pointer-to-path("/"), ("",))

// A schema path encodes segment for segment, with no `properties`.
#assert.eq(path-to-pointer(("work", "items")), "/work/items")
// A string segment that looks like an index comes back as an int.
#assert.eq(pointer-to-path(path-to-pointer(("0",))), (0,))
