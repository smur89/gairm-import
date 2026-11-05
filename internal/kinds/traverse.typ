// One schema traversal, through the kind descriptors, shared by lens,
// introspection and the strict-schema walkers. Paths are lens paths: a
// field name, "items" for an array's elements, "additionalProperties"
// for an object's additional schema. Unions and `not` are leaves here
// for now.

#import "registry.typ": _descriptor

#let _children(s) = (_descriptor(s).children)(s)

#let _child(s, seg) = {
  let hit = _children(s).find(((k, _)) => k == seg)
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

// Every (path, node) pair, pre-order. `more` lists extra
// (segment, node) pairs to walk into beyond a node's children.
#let _nodes(s, path: (), more: s => ()) = {
  let out = ((path, s),)
  for (seg, sub) in _children(s) + more(s) {
    out += _nodes(sub, path: path + (seg,), more: more)
  }
  out
}

// `s` with `f` applied to each child. As in lens paths, an object
// field literally named "additionalProperties" shadows the additional
// schema, so in that collision both writes land on the field.
#let _map-children(s, f) = _children(s).fold(s, (acc, (seg, sub)) => (
  (_descriptor(acc).with-child)(acc, seg, f(sub))
))
