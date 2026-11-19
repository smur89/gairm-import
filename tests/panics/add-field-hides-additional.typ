// expect: add-field key "additionalProperties" would hide the object's schema for other keys from schema paths.
#import "/lib.typ": add-field, map, string, number
#add-field(map(string()), ("additionalProperties",), number())
