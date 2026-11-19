// expect: schema-get path segment "properties" not in object shape. Valid keys: a. A schema path enters a field by its bare name, with no "properties" segment.
#import "/lib.typ": schema-get, object, string
#schema-get(object((a: string())), ("properties", "a"))
