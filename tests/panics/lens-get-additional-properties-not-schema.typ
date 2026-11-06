// expect: requires the object's `additional` field to be a schema dict
#import "../../lib.typ": lens-get, object, str-type
#lens-get(object((a: str-type)), ("additionalProperties",))
