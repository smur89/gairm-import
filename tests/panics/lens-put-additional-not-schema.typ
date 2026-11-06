// expect: lens-put value must be a schema; got: 42.
// Once written verbatim, which crashed later mid-walk.
#import "../../lib.typ": lens, lens-put, map, object, str-type
#lens-put(
  lens(("tags", "additionalProperties")),
  object((tags: map(str-type))),
  42,
)
