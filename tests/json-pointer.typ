// RFC 6901 JSON Pointer interop: path-to-pointer and pointer-to-path
// are inverses for the segments validate and lens paths produce (str
// object keys, int array indices).

#import "../lib.typ": path-to-pointer, pointer-to-path

// Each row: a path and its pointer, which encode and decode both ways.
#for (path, pointer) in (
  ((), ""),
  (("basics", "email"), "/basics/email"),
  // Mixed str + int, as validate reports an array element.
  (("work", 0, "highlights", 1), "/work/0/highlights/1"),
  (("nested", "items", 3, "sub", "deep"), "/nested/items/3/sub/deep"),
  // `/` in a key escapes as `~1`, `~` as `~0`. Encoding `~` first means
  // a `/` isn't escaped twice; decoding `~1` first means `~01` reads as
  // `~` + `1`, not `/` + `0`.
  (("a/b",), "/a~1b"),
  (("~tilde",), "/~0tilde"),
  (("a~b/c",), "/a~0b~1c"),
  (("~1",), "/~01"),
  // One empty-string segment: the root, then the "" key.
  (("",), "/"),
) {
  assert.eq(path-to-pointer(path), pointer, message: repr(path))
  assert.eq(pointer-to-path(pointer), path, message: pointer)
}

// Only `0` or `[1-9][0-9]*` decodes to an array index, so a leading
// zero stays a key, and so do "-0" and an index too large for an int.
#for (pointer, path) in (
  ("/work/01", ("work", "01")),
  ("/00", ("00",)),
  ("/-0", ("-0",)),
  ("/9223372036854775807", (9223372036854775807,)),
  ("/9223372036854775808", ("9223372036854775808",)),
  ("/99999999999999999999", ("99999999999999999999",)),
) {
  assert.eq(pointer-to-path(pointer), path, message: pointer)
  assert.eq(path-to-pointer(path), pointer, message: pointer)
}
