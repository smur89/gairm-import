// if / then / else: the one applicator that joins its node's other
// keywords. `{A…, if: I, then: T, else: E}` is
// `if-of(I, then: allOf(A, T), otherwise: allOf(A, E))`, each branch
// through the allOf merge (all-of.typ), so it has the merge's limits:
// with sibling keywords, the siblings and each branch must be object
// schemas. With none, the branches are T and E as they are, of any kind.

#import "../kinds/structure.typ": if-of
#import "keyword.typ": _role-of, _lone-hints, _into, _keywords
#import "../kinds/registry.typ": _nullable-member
#import "all-of.typ": _join, _restricts-extras

// A branch read beside its siblings, as draft 7 reads it: a branch
// with no `type` takes the siblings', since only a value of their type
// reaches it; and one that doesn't declare `additionalProperties`
// restricts no keys of its own, so it takes the siblings'
// `additionalProperties` and `properties` (its own properties win, and
// the merge then bails on any that differ). Without them the merge
// would read `then: {required: ["b"]}` as a closed object that has no
// `b`. A branch that is a `$ref` or a composition is merged as written,
// and so is one that is no object schema (an `enum`, a `type` without
// `object`, a keyword for another type): the merge then names it as it
// is, rather than by keywords it took from its siblings.
#let _objectish(b) = {
  let types = b.at("type", default: "object")
  (
    "enum" not in b
      and "const" not in b
      and "object" in (if type(types) == array { types } else { (types,) })
      and b
        .keys()
        .all(k => (
          "object"
            in _keywords.at(k, default: (:)).at("types", default: ("object",))
        ))
  )
}
#let _beside(branch, siblings) = {
  if (
    type(branch) != dictionary
      or branch.keys().any(k => _role-of(k) in _lone-hints)
      or not _objectish(branch)
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

#let _who = "the siblings of \"if\" and its branches"

// The condition is only a test, so it translates as draft 7 reads it:
// every object in it with no `additionalProperties` is open
// (`open-objects`, build.typ), so `{properties: {country: {const:
// "US"}}}` holds for an address with more keys than `country`. An `if`
// with neither branch checks nothing (draft 7), so the node translates
// without it, once its condition has been checked. The siblings
// translate once and join each branch; siblings that are only `type:
// "object"` add nothing a branch doesn't take from _beside, so a branch
// stands alone, as the object its siblings say it is. The branches
// translate in a loop, not a `.map`, to spend no call depth.
#let _conditional(js, ctx, recur) = {
  let siblings = js
    .pairs()
    .filter(((k, _)) => k != "if" and _role-of(k) != "branch")
    .to-dict()
  let cond = recur(js.at("if"), (.._into(ctx, "if"), open-objects: true))
  if "then" not in js and "else" not in js { return recur(siblings, ctx) }
  let plain = siblings.keys().filter(k => _role-of(k) != "annotation")
  let lone = plain == ()
  let types = siblings.at("type", default: none)
  let typed = (
    plain == ("type",)
      and (
        types == "object"
          or (type(types) == array and types.dedup() == ("object",))
      )
  )
  let base = if not lone and not typed { recur(siblings, ctx) }
  let base-restricts = if base != none { _restricts-extras(siblings, ctx) }
  let parts = (:)
  for (arg, k) in (("then", "then"), ("otherwise", "else")) {
    if k not in js {
      // With no branch, the siblings alone: `{type: "object"}` bails
      // as an open object, as it does anywhere.
      if base != none { parts.insert(arg, base) } else if typed {
        parts.insert(arg, recur(siblings, ctx))
      }
      continue
    }
    let at = _into(ctx, k)
    if lone {
      parts.insert(arg, recur(js.at(k), at))
      continue
    }
    let b = _beside(js.at(k), siblings)
    let node = recur(b, at)
    if base == none {
      // Only an object reaches the branch, so a nullable one is its
      // object, and the merge of one member checks it is an object.
      let x = _nullable-member(node)
      if x != none { node = x }
      node = _join((node,), (false,), (b,), (at,), ctx, who: _who)
    } else {
      node = _join(
        (base, node),
        (base-restricts, _restricts-extras(b, at)),
        (siblings, b),
        (ctx, at),
        ctx,
        who: _who,
      )
    }
    parts.insert(arg, node)
  }
  if-of(cond, ..parts)
}
