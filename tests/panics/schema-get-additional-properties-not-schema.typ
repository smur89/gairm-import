// expect: schema-get path segment "additionalProperties" needs the object's `additional` to be a schema, got: none.
#import "../../lib.typ": schema-get, object, string
#schema-get(object((a: string())), ("additionalProperties",))
