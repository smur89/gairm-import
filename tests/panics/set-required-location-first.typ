// expect: set-required's first argument must be a schema; got: (lens: ()).
#import "../../lib.typ": lens, set-required, object, str-type
#set-required(lens(()), object((a: str-type)), ("a",))
