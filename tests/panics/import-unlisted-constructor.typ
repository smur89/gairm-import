// expect: internal — constructor array-of is listed for no kind.
// The load-time coverage check, run on a catalog that forgets the
// array constructor.
#import "../../internal/kinds/catalog.typ": _check-coverage, _constructors
#import "../../internal/kinds/registry.typ": _kinds
#import "../../internal/kinds/structure.typ" as structure-mod
#let constructors = _constructors
#constructors.insert("array", ())
#_check-coverage(_kinds, constructors, (structure-mod,))
