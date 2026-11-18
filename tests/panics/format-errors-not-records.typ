// expect: format-errors errors must be an array of error records, as validate returns them, got: "oops".
#import "../../lib.typ": format-errors
#format-errors("oops")
