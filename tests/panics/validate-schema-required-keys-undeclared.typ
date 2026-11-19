// expect: validate schema field "required-keys" must be only declared fields (the object takes no other keys), got: "a".
// A hand-built closed object meets object()'s rules too.
#import "../../lib.typ": validate
#validate((kind: "object", shape: (:), required-keys: ("a",)), (:))
