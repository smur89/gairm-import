// if / then / else: the one applicator that joins its node's other
// keywords. `{A…, if: I, then: T, else: E}` is
// `if-of(I, then: allOf(A, T), otherwise: allOf(A, E))`, each branch
// through the allOf merge (all-of.typ), so it has the merge's limits:
// with sibling keywords, the siblings and each branch must be object
// schemas. With none, the branches are T and E as they are, of any kind.

#import "../kinds/structure.typ": if-of
#import "keyword.typ": _role-of
#import "all-of.typ": _all-of

// A branch read beside its siblings, as draft 7 reads it: a branch
// with no `type` takes the siblings', since only a value of their type
// reaches it; and one that doesn't declare `additionalProperties`
// restricts no keys of its own, so it takes the siblings'
// `additionalProperties` and `properties` (its own properties win, and
// the merge then bails on any that differ). Without them the merge
// would read `then: {required: ["b"]}` as a closed object that has no
// `b`. A branch that is a `$ref` or a composition is merged as written.
#let _beside(branch, siblings) = {
  if (
    type(branch) != dictionary
      or branch.keys().any(k => _role-of(k) in ("applicator", "ref"))
  ) { return branch }
  let b = branch
  if "type" not in b and "type" in siblings {
    b.insert("type", siblings.type)
  }
  if "additionalProperties" not in b {
    if "additionalProperties" in siblings {
      b.insert("additionalProperties", siblings.additionalProperties)
    }
    let own = b.at("properties", default: (:))
    let theirs = siblings.at("properties", default: (:))
    if (
      type(own) == dictionary and type(theirs) == dictionary and theirs != (:)
    ) {
      b.insert("properties", (:..theirs, ..own))
    }
  }
  b
}

// The condition is only a test, so it translates as draft 7 reads it:
// every object in it with no `additionalProperties` is open
// (`open-objects`, build.typ), so `{properties: {country: {const:
// "US"}}}` holds for an address with more keys than `country`. An `if`
// with neither branch checks nothing (draft 7), so the node translates
// without it.
#let _conditional(js, ctx, recur, resolve) = {
  let siblings = js
  for k in ("if", "then", "else") {
    if k in siblings { let _ = siblings.remove(k) }
  }
  if "then" not in js and "else" not in js { return recur(siblings, ctx) }
  let cond = recur(js.at("if"), (..ctx, open-objects: true))
  let alone = siblings.keys().all(k => _role-of(k) == "annotation")
  let branch(k) = if alone {
    if k in js { recur(js.at(k), ctx) }
  } else if k not in js { recur(siblings, ctx) } else {
    _all-of(
      (siblings, _beside(js.at(k), siblings)),
      ctx,
      recur,
      resolve,
      who: "the siblings of \"if\" and its branches",
      hint: "Non-object composition is out of scope: move the sibling keywords into \"then\" and \"else\".",
    )
  }
  if-of(cond, then: branch("then"), otherwise: branch("else"))
}
