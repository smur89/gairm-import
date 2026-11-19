// expect: internal — constructors are listed for "boolean", which has no descriptor.
// The load-time coverage check, run on a registry missing a kind that
// leaf.typ exports a constructor for.
#import "../../internal/kinds/catalog.typ": _check-coverage, _constructors
#import "../../internal/kinds/registry.typ": _kinds
#import "../../internal/kinds/leaf.typ" as leaf-mod
#let kinds = _kinds
#let _ = kinds.remove("boolean")
#_check-coverage(kinds, _constructors, (leaf-mod,))
