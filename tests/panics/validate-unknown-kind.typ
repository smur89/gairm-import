// expect: internal — unknown schema kind "bogus"
#import "../../lib.typ": object, validate
#validate((a: 1), schema: object((a: (kind: "bogus"))))
