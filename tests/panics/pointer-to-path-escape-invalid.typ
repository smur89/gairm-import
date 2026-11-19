// expect: pointer-to-path pointer token must be escaped only as RFC 6901 allows, `~0` (tilde) and `~1` (slash), got: "a~2".
#import "../../lib.typ": pointer-to-path
#pointer-to-path("/a~2")
