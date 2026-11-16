// expect: requires the object's `additional` field to be a schema dict
#import "../../lib.typ": lens-get, object, string
#lens-get(object((a: string())), ("additionalProperties",))
