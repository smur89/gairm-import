// expect: is missing iso8601 leaves
#import "../../internal/json-resume/schema.typ": (
  _assert-no-iso8601-leaves, _iso8601-source,
)
#import "../../lib.typ": any-of, array-of, object, str-type
// An iso8601 leaf nested in a union inside an array, as an unlisted
// upstream field would be.
#_assert-no-iso8601-leaves(
  object((a: array-of(any-of((str-type, _iso8601-source))))),
  "_iso8601-date-paths",
)
