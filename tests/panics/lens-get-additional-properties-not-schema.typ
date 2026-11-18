// expect: lens-get path segment "additionalProperties" needs the object's `additional` to be a schema, got: none.
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), ("additionalProperties",))
