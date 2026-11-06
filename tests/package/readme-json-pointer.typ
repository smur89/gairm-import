// Mirrors README.md, "JSON Pointer interop": each call and the result
// its comment shows. The asserts are ours.
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
