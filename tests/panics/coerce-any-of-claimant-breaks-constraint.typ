// expect: coerce at a: expected a value matching one of the union alternatives, got string.
// The string member claims "ab" and reports only a length miss, which
// coerce would ignore elsewhere; but no member matched, so there is no
// member to build the model from.
#import "../../lib.typ": any-of, bool-type, coerce, object, string
#coerce(
  object((
    a: any-of((
      (..string(), min-length: 5),
      bool-type,
    )),
  )),
  (a: "ab"),
)
