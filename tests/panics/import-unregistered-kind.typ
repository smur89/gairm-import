// expect: internal — str-type has kind "string", which has no descriptor.
// The load-time coverage check, run on a registry missing a kind that
// leaf.typ exports a constant for.
#import "../../internal/kinds/registry.typ": _check-coverage, _kinds
#import "../../internal/kinds/leaf.typ" as leaf-mod
#let kinds = _kinds
#let _ = kinds.remove("string")
#_check-coverage(kinds, (leaf-mod,))
