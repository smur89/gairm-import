// One schema traversal, through the kind descriptors, shared by lens
// and introspection. Paths are lens paths: a field name, "items" for an
// array's elements, "additionalProperties" for an object's additional
// schema, an int index for a union member, "not" for a `not` member,
// "if", "then" and "else" for a conditional's condition and branches.

#import "../core/error.typ": _fail, _problem
#import "registry.typ": _descriptor

#let _children(s) = (_descriptor(s).children)(s)

// Segments match by type as well as value, so `1.0` or `"0"` names no
// union member. A bad segment panics naming `who`, the public function
// that followed the path.
#let _child(s, seg, who) = {
  // A child with no segment (a shadowed additional schema) is never hit,
  // not even by a `none` segment.
  let hit = _children(s).find(((k, ..)) => (
    k != none and type(k) == type(seg) and k == seg
  ))
  if hit == none { _fail(who, (_descriptor(s).bad-segment)(s, seg)) }
  hit.at(1)
}

#let _get-at(s, path, who) = path.fold(s, (n, seg) => _child(n, seg, who))

// _child runs on the way down, before the node's writer is looked at,
// so a bad segment panics the same way from a put as from a get, a leaf
// (which has no writer) included.
#let _set-at(s, path, sub, who) = if path == () { sub } else {
  let (head, ..rest) = path
  let child = _child(s, head, who)
  (_descriptor(s).with-child)(s, head, _set-at(child, rest, sub, who), who)
}

// Every (path, node) pair, pre-order, of the nodes a path reaches: a
// child with no segment (a shadowed additional schema) is skipped.
#let _nodes(s, path: ()) = {
  let out = ((path, s),)
  for (seg, sub, _) in _children(s) {
    if seg != none { out += _nodes(sub, path: path + (seg,)) }
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
