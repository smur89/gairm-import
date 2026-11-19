// expect: remove-field key "id" not in object shape. Valid keys: none. It is only required: use unset-required(s, (), ("id",)).
#import "/lib.typ": remove-field, map, string
#remove-field(map(string(), required-keys: ("id",)), ("id",))
