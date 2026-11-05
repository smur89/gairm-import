// expect: unset-required expects an object schema at the lens target
#import "../../lib.typ": lens, object, str-type, unset-required
#unset-required(object((a: str-type)), lens(("a",)), ("k",))
