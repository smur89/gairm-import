// expect: validate schema field "additional" must be true or a schema (leave it out to reject other keys), got: 5.
#import "../../lib.typ": validate
#validate((kind: "object", shape: (:), additional: 5), (:))
