// One schema traversal, through the kind descriptors, shared by lens,
// introspection and the strict-schema walkers. Paths are lens paths: a
// field name, "items" for an array's elements, "additionalProperties"
// for an object's additional schema, an int index for a union member,
// "not" for a `not` member.

#import "registry.typ": _descriptor

#let _children(s) = (_descriptor(s).children)(s)

// Segments match by type as well as value, so `1.0` or `"0"` names no
// union member.
#let _child(s, seg) = {
  let hit = _children(s).find(((k, _)) => type(k) == type(seg) and k == seg)
  if hit == none {
    panic("gairm-import: " + (_descriptor(s).bad-segment)(s, seg))
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
  for (seg, sub) in _children(s) {
    out += _nodes(sub, path: path + (seg,))
  }
  out
}

// `s` with `f` applied to each child. As in lens paths, an object
// field literally named "additionalProperties" shadows the additional
// schema, so in that collision both writes land on the field.
#let _map-children(s, f) = _children(s).fold(s, (acc, (seg, sub)) => (
  (_descriptor(acc).with-child)(acc, seg, f(sub))
))
