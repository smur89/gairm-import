// Schema-shape inspection helpers. Debugging an extension schema
// otherwise means `repr(schema)` (noisy dict dump) or hand-walking
// `.shape` accessors. Introspection here stays read-only; edits live
// in lens.typ.
//
// Path tuples use lens-compatible segments — `"items"` for array
// descent, `"additionalProperties"` for the additional schema, an
// index for a union member, `"not"` for a `not` member, `"if"`,
// `"then"` and `"else"` for a conditional's condition and branches — so
// `paths-of-kind` output round-trips through `lens-get`.
// The `[]` suffix and the `*` row in `describe-schema` are
// display-only (`*` is the conventional shorthand for "any key").

#import "core/error.typ": _a, _fail, _problem
#import "kinds/registry.typ": _kinds, _descriptor
#import "kinds/catalog.typ": _constructor
#import "kinds/structure.typ": _require-schema
#import "kinds/walk.typ": _kind-label
#import "kinds/traverse.typ": _children, _paths-where
#import "kinds/constraint.typ": _constraint-rows

// The kinds paths-of-kind can look for: every kind but the plain
// containers. A union, `not` or conditional is found as a node, and
// its children are searched too.
#let _searchable-kinds = _kinds.keys().filter(k => _kinds.at(k).searchable)

#let _leaf(s) = _descriptor(s).with-child == none
#let _suffix(s) = (_descriptor(s).suffix)(s)

// Widths count grapheme clusters, as a reader sees them: `seán` is four
// wide, not five bytes.
#let _width(s) = s.clusters().len()
#let _pad-right(s, width) = s + " " * (width - _width(s))

// What a node sets beyond its kind, in one shared list: every
// constraint row it sets, in row order, by the row's field name (as the
// node and the error's `expected` spell it). A flag row shows by name
// alone.
#let _extras(s) = {
  let out = ()
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

// A node its descriptor draws as another node plus a mark
// (`nullable(X)` as `X?`), as (node, mark); any other node as itself
// with no mark.
#let _shown(s) = {
  let short = (_descriptor(s).shorthand)(s)
  if short == none { (s, "") } else { (short.of, short.mark) }
}

// A leaf's text: its kind, its mark, then what it sets beyond it.
#let _text(s, mark) = _suffix(s) + mark + _paren(s)

// The tree layout is where an inline kind (an array) differs from the
// rest: its one child extends its parent's row with the child's label
// (`[]`, then the array's own constraints), while every other child
// gets a row of its own.
#let _inline(s) = _descriptor(s).inline

// One child row. A leaf, or an array of leaves, is inline after its
// label, padded to the kind column; anything else gets a header line,
// with its own header text (`any of`) when it has one, and its own
// block below it. An array's constraints follow its element's text
// inline, and its label otherwise, so they don't widen the column.
// A mark follows a leaf's kind or a block's header, and the label of
// a node drawn by its label alone (an object, an array, a `not`).
#let _row(label, sub) = {
  let (sub, mark) = _shown(sub)
  let (label, sub, mark, after) = if _inline(sub) {
    let (_, elem, elem-label) = _children(sub).first()
    let (elem, elem-mark) = _shown(elem)
    (label + mark + elem-label, elem, elem-mark, _paren(sub))
  } else { (label, sub, mark, "") }
  if _leaf(sub) { return (label: label, text: _text(sub, mark) + after) }
  let head = _suffix(sub)
  if head == none {
    (label: label + mark + after, head: none, block: sub)
  } else { (label: label + after, head: head + mark, block: sub) }
}

// Recursive pretty-printer. `indent` prefixes every line at this
// depth; nested blocks add two more spaces. A node's header text is
// drawn by its parent's row; a node `alone` (the root), a leaf or an
// inline node draws its own, as a row with no label and no column.
#let _describe(schema, indent, alone: false) = {
  if alone or _leaf(schema) or _inline(schema) {
    let r = _row("", schema)
    let line = (
      r.label
        + if "text" in r { " " + r.text } else if r.head != none {
          " " + r.head
        }
    ).trim(at: start)
    if "text" in r { return indent + line }
    if line == "" { return _describe(r.block, indent) }
    return indent + line + ":\n" + _describe(r.block, indent + "  ")
  }
  // Each child under its label: a field name (`*` when required), `*`
  // for an object's additional schema, `[i]` for a union member, `not`
  // for a `not` member, `if`, `then` and `else` for a conditional's
  // condition and branches. `additional: true` shows as `* any`.
  let rows = _children(schema).map(((_, sub, label)) => _row(label, sub))
  if schema.at("additional", default: none) == true {
    rows.push((label: "*", text: "any"))
  }
  let aligned = rows.filter(r => "text" in r or r.head != none)
  let col = if aligned == () { 0 } else {
    calc.max(..aligned.map(r => _width(r.label))) + 2
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
/// members are listed as `[0]`, `[1]`, …, a `not` member as `not`, a
/// conditional's condition and branches as `if`, `then` and `else`, and
/// a dependent-required entry shows as `trigger → dependents`.
///
/// - schema (dictionary): The schema to draw.
/// -> str
#let describe-schema(schema) = {
  _require-schema(schema, "describe-schema schema")
  _describe(schema, "", alone: true)
}

// A node matches a schema-node query when it is of the query's kind and
// has every other field the query sets, with the same value. So
// `string()` finds every string, `string(format: "date")` the date
// strings, with a pattern or without, and `number(minimum: 0)` the
// numbers whose minimum is 0.
#let _matches(query, node) = (
  query.pairs().all(((k, v)) => k == "kind" or (k in node and node.at(k) == v))
)

// What paths-of-kind looks for, as (kind, test, name): a schema node
// finds the nodes of its kind it _matches, a constructor the nodes its
// test holds for (catalog.typ), and anything else is of
// no kind, which no search takes. `name` says what the query was, for
// the panic: a whole node's repr can run to pages.
#let _query(kind) = if type(kind) == dictionary and "kind" in kind {
  (
    kind: kind.kind,
    test: n => _matches(kind, n),
    // A kind the registry doesn't know may not even be a string, so it
    // is named as given.
    name: if (
      type(kind.kind) == str
        and kind.kind in _kinds
        and type(kind.at("format", default: "")) == str
    ) {
      _a(_kind-label(kind)) + " schema"
    } else { "a node of kind " + repr(kind.kind) },
  )
} else if type(kind) == function {
  let c = _constructor(kind)
  if c == none { (kind: none, name: repr(kind)) } else {
    (kind: c.kind, test: c.test, name: repr(kind))
  }
} else { (kind: none, name: repr(kind)) }

// Container kinds (`object`, `array`) are deliberately rejected — the
// walker descends through them, and a search for one is more likely a
// typo for a leaf than a question.
/// Lists the lens path of every node in `schema` that matches `kind`,
/// including inside union and `not` members and a conditional's
/// condition and branches. The paths work wherever a location does.
/// Panics for `object` and `array`, which the search walks through, and
/// for anything that is not a schema or a constructor.
///
/// - schema (dictionary): The schema to search.
/// - kind (dictionary, function): What to find: a schema node such as
///   `string(format: "date")`, or a constructor such as `string`,
///   `enum-of`, `any-of` or `if-of`. A node finds the nodes of its kind
///   that also have every field it sets, with the same value:
///   `string()` finds every string, `string(format: "date")` only the
///   date strings, `number()` numbers but not integers, and
///   `number(minimum: 0)` only the numbers with minimum 0. A
///   constructor finds the nodes it builds: `enum-of` every enum,
///   `const-of` the single-value ones, `any-of` and `one-of` their own
///   unions, and `nullable` the nullable ones.
/// -> array
#let paths-of-kind(schema, kind) = {
  _require-schema(schema, "paths-of-kind schema")
  let q = _query(kind)
  if q.kind not in _searchable-kinds {
    _fail("paths-of-kind", _problem(
      "kind",
      "a schema node or a constructor of a kind it can find ("
        + _searchable-kinds.join(", ")
        + "); object and array are walked through, not searched for",
      q.name,
    ))
  }
  // A node query is a schema like any other: a malformed field (a
  // string's format) fails here, in the package's words.
  if type(kind) == dictionary { _require-schema(kind, "paths-of-kind kind") }
  _paths-where(schema, n => n.kind == q.kind and (q.test)(n))
}
