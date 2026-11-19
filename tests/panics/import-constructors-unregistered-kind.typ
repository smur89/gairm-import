// expect: internal — constructors are listed for "not", which has no descriptor.
// The load-time coverage check, run on a registry missing a kind the
// catalog lists constructors for.
#import "../../internal/kinds/catalog.typ": _check-coverage, _constructors
#import "../../internal/kinds/registry.typ": _kinds
#let kinds = _kinds
#let _ = kinds.remove("not")
#_check-coverage(kinds, _constructors, ())
