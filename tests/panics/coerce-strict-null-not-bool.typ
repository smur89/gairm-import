// expect: coerce strict-null must be true or false, got: "yes".
#import "../../lib.typ": coerce, string
#coerce(string(), "x", strict-null: "yes")
