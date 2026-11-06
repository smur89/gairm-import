// expect: internal — constructor array-of is in no descriptor's constructors.
// The load-time coverage check, run on a registry whose array
// descriptor forgets its constructor.
#import "../../internal/kinds/registry.typ": _check-coverage, _kinds
#import "../../internal/kinds/structure.typ" as structure-mod
#let kinds = _kinds
#kinds.array.insert("constructors", ())
#_check-coverage(kinds, (structure-mod,))
