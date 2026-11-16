// One schema traversal, through the kind descriptors, shared by lens
// and introspection. Paths are lens paths: a field name, "items" for an
// array's elements, "additionalProperties" for an object's additional
// schema, an int index for a union member, "not" for a `not` member,
// "if", "then" and "else" for a conditional's condition and branches.

#import "../core/error.typ": _bail, _fail, _problem
#import "registry.typ": _descriptor

#let _children(s) = (_descriptor(s).children)(s)

// Segments match by type as well as value, so `1.0` or `"0"` names no
// union member.
#let _child(s, seg) = {
  let hit = _children(s).find(((k, ..)) => type(k) == type(seg) and k == seg)
  if hit == none {
    _bail(none, (_descriptor(s).bad-segment)(s, seg))
  }
  hit.at(1)
}

#let _get-at(s, path) = path.fold(s, _child)

// _child runs on the way down, so a bad segment panics the same way
// from a put as from a get.
#let _set-at(s, path, sub) = if path == () { sub } else {
  let (head, ..rest) = path
  (_descriptor(s).with-child)(s, head, _set-at(_child(s, head), rest, sub))
}

// Every (path, node) pair, pre-order.
#let _nodes(s, path: ()) = {
  let out = ((path, s),)
  for (seg, sub, _) in _children(s) {
    out += _nodes(sub, path: path + (seg,))
  }
  out
}

// The path of every node in `s` that `keep` holds for, pre-order.
#let _paths-where(s, keep) = (
  _nodes(s).filter(((_, n)) => keep(n)).map(((p, _)) => p)
)

// A location: where lens and introspection functions point. A lens
// `(lens: path)`, or a bare path array. Neither is a schema node: an
// array is not a dictionary, and a lens has no `kind`.
#let _is-lens(x) = (
  type(x) == dictionary and x.keys() == ("lens",) and type(x.lens) == array
)
#let _is-location(x) = type(x) == array or _is-lens(x)

// The path a location names. Panics, naming `who`, on anything else.
#let _location-path(at, who) = {
  if type(at) == array { return at }
  if _is-lens(at) { return at.lens }
  _fail(who, _problem("location", "a lens or a path array", repr(at)))
}
