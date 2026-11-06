// expect: any-of() members must be a non-empty array of schema dicts (each built with the constructors); got: ((lens: ("a",)),).
#import "../../lib.typ": lens, any-of
#any-of((lens(("a",)),))
