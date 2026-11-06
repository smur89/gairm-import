// expect: object() additional must be none, false, true, or a schema dict
#import "../../lib.typ": object, str-type
#object((a: str-type), additional: (kind: "bogus"))
