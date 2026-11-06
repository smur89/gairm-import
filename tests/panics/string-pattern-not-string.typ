// expect: string() pattern must be a regex or a string, got: integer.
#import "../../lib.typ": string
#string(pattern: 1)
