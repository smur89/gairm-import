// expect: unknown schema kind "bogus"; build schemas with the constructors.
// Hand-built, since the constructors reject an unknown kind.
#import "../../lib.typ": coerce
#coerce(
  (a: 1),
  schema: (kind: "object", shape: (a: (kind: "bogus")), required-keys: ()),
)
