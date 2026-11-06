// expect: kind-at location must be a lens or a path array; got: "basics".
#import "../../lib.typ": kind-at, resume-schema
#kind-at(resume-schema, "basics")
