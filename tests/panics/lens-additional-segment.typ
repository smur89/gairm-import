// expect: requires the object's `additional` field to be a schema dict
#import "../../lib.typ": lens, lens-get, object, str-type
#lens-get(lens(("additionalProperties",)), object((a: str-type)))
