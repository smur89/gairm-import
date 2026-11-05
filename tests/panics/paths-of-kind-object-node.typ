// expect: is not a recognised leaf kind
#import "../../lib.typ": paths-of-kind, resume-schema, object, str-type
#paths-of-kind(resume-schema, object((a: str-type)))
