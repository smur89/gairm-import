// expect: unknown schema kind "bogus"; build schemas with the constructors.
// Hand-built, since the constructors reject an unknown kind.
#import "../../lib.typ": validate
#validate(
  (kind: "object", shape: (a: (kind: "bogus")), required-keys: ()),
  (a: 1),
)
