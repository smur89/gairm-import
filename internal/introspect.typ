// Schema-shape inspection helpers. Debugging an extension schema
// otherwise means `repr(schema)` (noisy dict dump) or hand-walking
// `.shape` accessors. Introspection here stays read-only; edits live
// in lens.typ.
//
// Path tuples use lens-compatible segments — `"items"` for array
// descent, `"additionalProperties"` for the additional schema, an
// index for a union member, `"not"` for a `not` member — so
// `paths-of-kind` output round-trips through `lens` and `lens-get`.
// The `[]` suffix and the `*` row in `describe-schema` are
// display-only (`*` is the conventional shorthand for "any key").

#import "kinds/registry.typ": _kinds, _descriptor
#import "kinds/traverse.typ": _children, _get-at, _nodes

// The kinds paths-of-kind can look for: every kind but the plain
// containers. A union or `not` is found as a node, and its members
// are searched too.
#let _leaf-kinds = _kinds.keys().filter(k => _kinds.at(k).searchable)

// describe-schema still draws a union or `not` on one row, by its
// suffix: every kind paths-of-kind finds.
#let _leaf(s) = _descriptor(s).searchable
#let _suffix(s) = (_descriptor(s).suffix)(s)

#let _pad-right(s, width) = s + " " * (width - s.len())

// The tree layout is where arrays and objects differ: an array's
// element extends its parent's row with `[]`, while each object field
// gets a row of its own.
#let _is-array(s) = s.kind == "array"
#let _elem(s) = _children(s).first().at(1)

// One object row. A leaf, or an array of leaves, is inline after its
// label, padded to the kind column; a container gets a header line and
// its own block below it.
#let _row(label, sub) = {
  let (label, sub) = if _is-array(sub) { (label + "[]", _elem(sub)) } else {
    (label, sub)
  }
  if _leaf(sub) { (label: label, text: _suffix(sub)) } else {
    (label: label, block: sub)
  }
}

// Recursive pretty-printer. `indent` prefixes every line at this
// depth; nested blocks add two more spaces.
#let _describe(schema, indent) = {
  if _leaf(schema) { return indent + _suffix(schema) }
  if _is-array(schema) {
    let elem = _elem(schema)
    return if _leaf(elem) { indent + "[] " + _suffix(elem) } else {
      indent + "[]:\n" + _describe(elem, indent + "  ")
    }
  }
  // An object: its fields, then its additional schema under `*`, the
  // display-only key for "any other key" (lens paths say
  // "additionalProperties"); `additional: true` shows as `any`.
  let rows = _children(schema)
    .enumerate()
    .map(((i, (seg, sub))) => _row(
      if i < schema.shape.len() { seg } else { "*" },
      sub,
    ))
  if schema.at("additional", default: none) == true {
    rows.push((label: "*", text: "any"))
  }
  let inline = rows.filter(r => "text" in r)
  let col = if inline == () { 0 } else {
    calc.max(..inline.map(r => r.label.len())) + 2
  }
  let lines = rows.map(r => if "text" in r {
    indent + _pad-right(r.label, col) + r.text
  } else {
    indent + r.label + ":\n" + _describe(r.block, indent + "  ")
  })
  if lines == () { "" } else { lines.join("\n") }
}

/// Draws a schema as an indented tree, one line per field with its kind.
/// Keys are sorted, arrays are suffixed `[]`, and `*` stands for any
/// other key.
///
/// - schema (dictionary): The schema to draw.
/// -> str
#let describe-schema(schema) = _describe(schema, "")

// A schema node matches by its kind (so integer-type finds every
// number). A kind name string is deprecated, for removal in the next
// major.
#let _kind-name-of(kind) = {
  if type(kind) == dictionary and "kind" in kind { return kind.kind }
  if type(kind) == function {
    let hit = _kinds.pairs().find(((_, d)) => d.constructors.contains(kind))
    if hit != none { return hit.at(0) }
  }
  kind
}

// Container kinds (`object`, `array`) are deliberately rejected — the
// walker descends through them, and a search for one is more likely a
// typo for a leaf than a question.
/// Lists the lens path of every node in `schema` that has the given
/// kind, including inside union and `not` members. The paths work with
/// `lens`. Panics for `object` and `array`, which the search walks
/// through, and for kinds it does not know.
///
/// - schema (dictionary): The schema to search.
/// - kind (dictionary, function, str): The kind to find: a schema node
///   such as `date-string` (matched by its kind, so `integer-type` finds
///   every number), or a constructor such as `pattern-string`, `enum-of`,
///   `const-of`, `any-of`, `one-of` or `not-of`. A kind name as a `str`
///   still works but is deprecated.
/// -> array
#let paths-of-kind(schema, kind) = {
  let kind-name = _kind-name-of(kind)
  if kind-name not in _leaf-kinds {
    panic(
      "gairm-import: paths-of-kind kind "
        + repr(kind)
        + " is not a recognised leaf kind. Pass a leaf schema "
        + "(e.g. date-string), a constructor (e.g. pattern-string), "
        + "or one of: "
        + _leaf-kinds.join(", ")
        + ".",
    )
  }
  _nodes(schema).filter(((_, n)) => n.kind == kind-name).map(((p, _)) => p)
}

// Same as `lens-get(lens(path), schema).kind` — keeps the common
// "what kind is at X" debugging step a single call.
/// The kind name of the schema node at `path`, such as `"str"` or
/// `"object"`. Panics if the path does not exist.
///
/// - schema (dictionary): The schema to look in.
/// - path (array): The lens path to the node.
/// -> str
#let kind-at(schema, path) = _get-at(schema, path).kind
