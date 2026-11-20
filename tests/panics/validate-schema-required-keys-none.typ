// expect: field "required-keys" must be an array of key names, got: none. Leave the field out
#import "/lib.typ": validate
#validate((kind: "object", shape: (:), required-keys: none), (:))
