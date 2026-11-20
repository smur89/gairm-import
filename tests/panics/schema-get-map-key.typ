// expect: schema-get path segment "x" not in object shape. Valid keys: none. "additionalProperties" enters the schema for other keys.
#import "/lib.typ": schema-get, map, string
#schema-get(map(string()), ("x",))
