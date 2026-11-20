// expect: internal — kind "not" has a descriptor but no constructors listed.
// The load-time coverage check, run on a catalog missing a kind the
// registry describes.
#import "../../internal/kinds/catalog.typ": _check-coverage, _constructors
#import "../../internal/kinds/registry.typ": _kinds
#let constructors = _constructors
#let _ = constructors.remove("not")
#_check-coverage(_kinds, constructors, ())
