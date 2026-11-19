// expect: pointer-to-path pointer must be "" or a pointer starting with "/", got: "a".
#import "../../lib.typ": pointer-to-path
#pointer-to-path("a")
