// expect: set-required expects an object schema at the lens target
#import "../../lib.typ": lens, object, set-required, str-type
#set-required(object((a: str-type)), lens(("a",)), ("k",))
