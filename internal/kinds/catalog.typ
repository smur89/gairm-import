// The public constructors of each kind, for the queries that start from
// one (paths-of-kind) and the load-time check that no kind or
// constructor is missed. It sits above registry.typ and the
// constructors' modules: the constructors check their sub-schemas
// against the registry's kinds, so the registry cannot list them.
//
// Each kind maps to its constructors as (function, test) pairs:
// paths-of-kind's query by that constructor finds the nodes of the kind
// the test holds for (one-of the exclusive unions). A bare function is
// a pair whose test holds for every node of the kind.

#import "../core/error.typ": _internal
#import "registry.typ": _kinds, _is-nullable
#import "leaf.typ" as _leaf-mod
#import "leaf.typ": number, integer, enum-of, const-of
#import "format.typ" as _format-mod
#import "format.typ": string
#import "structure.typ" as _structure-mod
#import "structure.typ": (
  array-of, object, map, any-of, one-of, not-of, if-of, nullable, _has-kind,
)

#let _constructors = {
  let listed = (
    string: (string,),
    number: (number,),
    integer: (integer,),
    enum: (enum-of, (const-of, s => s.values.len() == 1)),
    array: (array-of,),
    object: (object, map),
    union: (
      (any-of, s => not s.exclusive),
      (one-of, s => s.exclusive),
      // A nullable's first member must be a schema nullable() could
      // take; checked by kind, so a hand-built member is passed over.
      (nullable, s => _is-nullable(s) and _has-kind(s.members.first())),
    ),
    "not": (not-of,),
    "if": (if-of,),
  )
  listed
    .pairs()
    .map(((kind, cs)) => (
      kind,
      cs.map(c => if type(c) == array { c } else { (c, _ => true) }),
    ))
    .to-dict()
}

// The kind `fn` builds and its test, or none for a function that is no
// constructor. The load-time check passes its own `constructors`.
#let _constructor(fn, constructors: _constructors) = {
  for (kind, cs) in constructors {
    let hit = cs.find(((f, _)) => f == fn)
    if hit != none { return (kind: kind, test: hit.at(1)) }
  }
}

// Every kind listed here is registered, every exported constant names a
// registered kind, and every exported constructor is listed, so a new
// kind can't miss its descriptor or its constructors.
// `dictionary(module)` lists a module's names.
#let _check-coverage(kinds, constructors, modules) = {
  for kind in constructors.keys() {
    _internal(
      kind in kinds,
      "constructors are listed for "
        + repr(kind)
        + ", which has no descriptor.",
    )
  }
  for mod in modules {
    for (name, v) in dictionary(mod) {
      if name.starts-with("_") { continue }
      if type(v) == dictionary {
        _internal(
          v.at("kind", default: none) in kinds,
          name
            + " has kind "
            + repr(v.at("kind", default: none))
            + ", which has no descriptor.",
        )
      } else if type(v) == function {
        _internal(
          _constructor(v, constructors: constructors) != none,
          "constructor " + name + " is listed for no kind.",
        )
      }
    }
  }
}

#_check-coverage(_kinds, _constructors, (
  _leaf-mod,
  _format-mod,
  _structure-mod,
))
