// expect: paths-of-kind kind-name "object" is not a recognised leaf kind
#import "../../lib.typ": object, paths-of-kind, resume-schema
#paths-of-kind(resume-schema, "object")
