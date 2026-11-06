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
#import "kinds/constraint.typ": _constraint-rows

// The kinds paths-of-kind can look for: every kind but the plain
// containers. A union or `not` is found as a node, and its members
// are searched too.
#let _leaf-kinds = _kinds.keys().filter(k => _kinds.at(k).searchable)

#let _leaf(s) = _descriptor(s).leaf
#let _suffix(s) = (_descriptor(s).suffix)(s)
#let _labels(s) = (_descriptor(s).labels)(s)

#let _pad-right(s, width) = s + " " * (width - s.len())

// What a node sets beyond its kind, in one shared list: the `integer`
// flag, then every constraint row it sets, in row order, by the row's
// field name (as the node and the error's `expected` spell it). A
// flag row shows by name alone.
#let _extras(s) = {
  let out = if s.at("integer", default: false) == true { ("integer",) } else {
    ()
  }
  for row in _constraint-rows {
    let v = s.at(row.field, default: none)
    if v == none or v == false { continue }
    out.push(if v == true { row.field } else { row.field + " " + str(v) })
  }
  out
}
#let _paren(s) = {
  let extras = _extras(s)
  if extras == () { "" } else { " (" + extras.join(", ") + ")" }
}

// A leaf's text: its kind, then what it sets beyond it.
#let _text(s) = _suffix(s) + _paren(s)

// The tree layout is where arrays differ from the rest: an array's
// element extends its parent's row with `[]` (and the array's own
// constraints), while every other child gets a row of its own.
#let _is-array(s) = s.kind == "array"
#let _elem(s) = _children(s).first().at(1)

// One child row. A leaf, or an array of leaves, is inline after its
// label, padded to the kind column; anything else gets a header line,
// with its own header text (`any of`) when it has one, and its own
// block below it. An array's constraints follow its element's text
// inline, and its label otherwise, so they don't widen the column.
#let _row(label, sub) = {
  let (label, sub, after) = if _is-array(sub) {
    (label + "[]", _elem(sub), _paren(sub))
  } else { (label, sub, "") }
  if _leaf(sub) { (label: label, text: _text(sub) + after) } else {
    (label: label + after, head: _suffix(sub), block: sub)
  }
}

// Recursive pretty-printer. `indent` prefixes every line at this
// depth; nested blocks add two more spaces. A node's header text is
// drawn by its parent's row, or by describe-schema at the root.
#let _describe(schema, indent) = {
  if _leaf(schema) { return indent + _text(schema) }
  if _is-array(schema) {
    let r = _row("", schema)
    return if "text" in r { indent + r.label + " " + r.text } else {
      (
        indent
          + r.label
          + (if r.head != none { " " + r.head })
          + ":\n"
          + _describe(r.block, indent + "  ")
      )
    }
  }
  // Each child under its label: a field name (`*` when required), `*`
  // for an object's additional schema, `[i]` for a union member, `not`
  // for a `not` member. `additional: true` shows as `* any`.
  let rows = _labels(schema)
    .zip(_children(schema))
    .map(((label, (_, sub))) => _row(label, sub))
  if schema.at("additional", default: none) == true {
    rows.push((label: "*", text: "any"))
  }
  let aligned = rows.filter(r => "text" in r or r.head != none)
  let col = if aligned == () { 0 } else {
    calc.max(..aligned.map(r => r.label.len())) + 2
  }
  let lines = rows.map(r => if "text" in r {
    indent + _pad-right(r.label, col) + r.text
  } else {
    let head = if r.head == none { r.label } else {
      _pad-right(r.label, col) + r.head
    }
    indent + head + ":\n" + _describe(r.block, indent + "  ")
  })
  // An object's dependent-required, one trigger a line, after its
  // fields.
  for (trigger, deps) in schema
    .at("dependent-required", default: (:))
    .pairs()
    .sorted(key: p => p.at(0)) {
    lines.push(indent + trigger + " → " + deps.join(", "))
  }
  lines.join("\n", default: "")
}

/// Draws a schema as an indented tree, one line per field with its kind
/// and constraints. Keys are sorted, required fields are marked `*`,
/// arrays are suffixed `[]`, `*` stands for any other key, union
/// members are listed as `[0]`, `[1]`, … and a `not` member as `not`,
/// and a dependent-required entry shows as `trigger → dependents`.
///
/// - schema (dictionary): The schema to draw.
/// -> str
#let describe-schema(schema) = {
  let head = if _leaf(schema) or _is-array(schema) { none } else {
    _suffix(schema)
  }
  if head == none { _describe(schema, "") } else {
    head + ":\n" + _describe(schema, "  ")
  }
}

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
