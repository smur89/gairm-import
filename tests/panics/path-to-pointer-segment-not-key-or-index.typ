// expect: path-to-pointer path segment must be a string or a non-negative integer (an RFC 6901 array index), got: 1.5.
#import "../../lib.typ": path-to-pointer
#path-to-pointer((1.5,))
