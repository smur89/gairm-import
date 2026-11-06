// expect: internal — kind "str" has neither a check nor a walk.
// The load-time engine coverage check, run on a registry whose str
// descriptor lost its check.
#import "../../internal/kinds/registry.typ": _check-engine, _kinds
#let kinds = _kinds
#kinds.str.insert("check", none)
#_check-engine(kinds)
