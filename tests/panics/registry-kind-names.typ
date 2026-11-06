// expect: internal — the registered kinds
// The load-time check that structure.typ's kind list, which the
// constructors' schema check uses, names exactly the registered kinds.
#import "../../internal/kinds/registry.typ": _check-kind-names, _kinds
#import "../../internal/kinds/structure.typ": _schema-kinds
#_check-kind-names(_kinds, _schema-kinds.filter(k => k != "str"))
