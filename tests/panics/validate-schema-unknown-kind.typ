// expect: validate schema at ("a",) must be a schema, got: (kind: "bogus"). Build schemas with the constructors.
// Hand-built, since the constructors reject an unknown kind.
#import "../../lib.typ": validate
#validate(
  (kind: "object", shape: (a: (kind: "bogus")), required-keys: ()),
  (a: 1),
)
