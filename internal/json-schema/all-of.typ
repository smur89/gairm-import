// allOf: the object-merge subset. Each member translates on its own and
// the objects merge into one; what the merge can't express bails here.

#import "../kinds/structure.typ": object, nullable, _is-object
#import "../kinds/walk.typ": _kind-label
#import "../core/error.typ": _a
#import "keyword.typ": _bail, _json, _into, _require-member-array, _role-of
#import "ref.typ": _follow-refs

// Whether a raw allOf member declares `additionalProperties` false or a
// schema, through `$ref`, nested allOf, and the members of an anyOf (a
// nullable object is `anyOf: [{…}, {type: "null"}]`). Read from the
// JSON because the translated kind can't tell an explicit `false` from
// an undeclared one: object() stores both as no `additional`, and the
// translator reads an undeclared one as closed, where draft 7 reads it
// as open. Runs after the member translated, so its `$ref`s resolve
// without cycles.
#let _restricts-extras(js, ctx) = {
  let js = _follow-refs(js, ctx)
  for keyword in ("allOf", "anyOf") {
    if keyword in js {
      return js.at(keyword).any(m => _restricts-extras(m, ctx))
    }
  }
  // A schema that takes any value (`{}`) restricts nothing.
  let ap = js.at("additionalProperties", default: true)
  (
    ap != true
      and not (
        type(ap) == dictionary
          and ap.keys().all(k => _role-of(k) == "annotation")
      )
  )
}

// Every member must translate to an object schema; shapes union (a
// duplicate key must carry an EQUAL sub-schema), required-keys and
// dependent-required union, additionalProperties must agree across all
// members (undeclared counts as closed), and members that restrict
// extras (`restricts`, see _restricts-extras) need identical property
// sets. Non-object composition (e.g. string + extra constraints) stays
// out of scope; deep-merging conflicting sub-schemas is a rabbit hole
// the engine's flat kinds can't express. `ctxs` are where each member
// is, for the messages; `ctx` is the node the merge is for, and `who`
// names the members, so a conditional's branches (conditional.typ)
// bail in their own words.
#let _merge-all-of(members, restricts, ctxs, ctx, who) = {
  for (i, m) in members.enumerate() {
    if not _is-object(m) {
      _bail(
        ctxs.at(i),
        who
          + " must all be object schemas, got: "
          + _a(_kind-label(m))
          + " schema. Non-object composition is out of scope.",
      )
    }
  }
  let shape = (:)
  let required = ()
  let dependent = (:)
  for m in members {
    for (key, sub) in m.shape {
      if key in shape and shape.at(key) != sub {
        _bail(
          ctx,
          who + " declare conflicting schemas for key " + _json(key) + ".",
        )
      }
      shape.insert(key, sub)
    }
    required += m
      .at("required-keys", default: ())
      .filter(k => k not in required)
    // Same-trigger dependency lists union, like required-keys.
    for (trigger, dependents) in m.at("dependent-required", default: (:)) {
      let merged = dependent.at(trigger, default: ())
      dependent.insert(
        trigger,
        merged + dependents.filter(d => d not in merged),
      )
    }
  }
  // additionalProperties must agree across ALL members, with an
  // undeclared member counting as closed (`none`) — silently taking
  // the open (or typed) member's value would accept keys another
  // member rejects.
  let additionals = members.map(m => m.at("additional", default: none))
  for a in additionals {
    if a != additionals.at(0) {
      _bail(
        ctx,
        who
          + " declare conflicting additionalProperties (open, closed, and typed members must all agree).",
      )
    }
  }
  // Draft 7 applies each member's additionalProperties to that member's
  // own properties only: a closed member rejects, and a typed one
  // checks, keys only another member declares, which the union would
  // accept unchecked.
  let keys = members.map(m => m.shape.keys().sorted())
  if restricts.any(r => r) and keys.any(k => k != keys.at(0)) {
    _bail(
      ctx,
      who
        + " with `additionalProperties: false` or a schema must all declare the same properties: draft 7 applies each member's additionalProperties to its own properties only, so a merged schema would accept keys that member rejects. Declare the properties in every member, or drop the restriction.",
    )
  }
  object(
    shape,
    required-keys: required,
    dependent-required: dependent,
    additional: additionals.at(0),
  )
}

// X when `node` is nullable(X), else none.
#let _nullable-of(node) = {
  let members = node.at("members", default: ())
  if members != () and node == nullable(members.first()) {
    members.first()
  }
}

// The merge of already translated `members` (see _merge-all-of). A
// member translated from `type: ["object", "null"]` is
// nullable(object): its object merges. A null meets allOf only when
// every member takes it, so the merge is nullable only then.
#let _join(members, restricts, ctxs, ctx, who: "allOf members") = {
  let inner = members.map(m => _nullable-of(m))
  let merged = _merge-all-of(
    members.zip(inner).map(((m, x)) => if x == none { m } else { x }),
    restricts,
    ctxs,
    ctx,
    who,
  )
  if inner.all(x => x != none) { nullable(merged) } else { merged }
}

// The allOf applicator: the node's member schemas, each translated by
// `recur`, merged.
#let _all-of(js, ctx, recur) = {
  let (members, restricts, ctxs) = ((), (), ())
  for (i, m) in _require-member-array(js, "allOf", ctx).enumerate() {
    let at = _into(ctx, "allOf", i)
    members.push(recur(m, at))
    restricts.push(_restricts-extras(m, at))
    ctxs.push(at)
  }
  _join(members, restricts, ctxs, ctx)
}
