// expect: internal — unknown schema kind "bogus"
#import "../../lib.typ": coerce, object
#coerce((a: 1), schema: object((a: (kind: "bogus"))))
