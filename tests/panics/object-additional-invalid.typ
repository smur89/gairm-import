// expect: object() additional must be none, false, true, or a schema dict
#import "../../lib.typ": object, string
#object((a: string()), additional: 1)
