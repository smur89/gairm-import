// One descriptor per schema kind, so the engine, lens and
// introspection ask the registry instead of keeping their own `kind ==`
// ladders. A descriptor holds:
//
//   walk          (schema, value, ctx, recur) => (errors, value, fatal):
//                 what the engine runs (walk.typ; a leaf's is built from
//                 its check by _leaf-walk, leaf.typ)
//   searchable    find-paths finds it, rather than only walking
//                 through it
//   children      schema => ((segment, sub-schema, label), ..): segments
//                 as lens paths spell them, labels as describe-schema
//                 draws them
//   with-child    (schema, segment, sub) => the node with that child
//                 replaced; none for a leaf, which has no children. An
//                 object comes back as it is; the lens write rebuilds
//                 it through object() (traverse.typ)
//   suffix        schema => what describe-schema prints on the node's own
//                 row: by default a leaf's kind, and no header (none)
//                 for a node with children
//   inline        describe-schema draws the node's one child on its
//                 parent's row, extended by the child's label (an
//                 array's elements as `name[]`)
//   shorthand     schema => none, or (of, mark): describe-schema draws
//                 the node as `of` with `mark` (a nullable as `X?`)
//   bad-segment   (schema, segment) => the problem (error.typ) a lens
//                 reports when the segment names no child
//   fields        ((field, required, ok, must), ..): the node's own
//                 fields the walk reads. `ok` judges a present value, or
//                 is none for a sub-schema, which is checked as a schema
//                 of its own; `must` says what the value must be
//   rows          the constraint rows (constraint.typ) its fields may set
//   problem       none, or schema => the problem (error.typ) with the
//                 node's fields that `fields` can't state, or none.
//                 structure.typ's _schema-problem reads all three
//
// The constructors that build each kind are listed in catalog.typ: they
// sit above this registry, since their schema check reads its kinds.

#import "leaf.typ": (
  null-type, _leaf-walk, _string-check, _number-check, _integer-check,
  _bool-check, _null-check, _any-check, _enum-check,
)
#import "../core/error.typ": _a, _not-in, _problem, _key-names-problem
#import "constraint.typ": _constraint-rows
#import "format.typ": _string-kind-check, _string-problem
#import "walk.typ": (
  _array-walk, _object-walk, _union-walk, _not-walk, _if-walk, _kind-label,
)

// `nullable(X)`'s shape: an any-of of exactly X then null, read off the
// node, since nullable() sits above this registry.
#let _is-nullable(s) = (
  not s.exclusive and s.members.len() == 2 and s.members.last() == null-type
)

// A conditional's children, as (segment, field): the lens segments are
// the JSON Schema keywords, the fields if-of()'s arguments (`else` is a
// Typst keyword).
#let _if-parts = (("if", "cond"), ("then", "then"), ("else", "otherwise"))
// The (segment, field) pairs of the parts `s` has.
#let _if-present(s) = _if-parts.filter(((_, field)) => field in s)

// `p` with its argument named as a node's field (`field "format"`), for
// a problem a constructor's check words for its argument.
#let _as-field(p) = if p != none and p.at("arg", default: none) != none {
  (..p, arg: "field " + repr(p.arg))
} else { p }

// The problem (error.typ) with object()'s `required-keys`,
// `dependent-required` and `additional` arguments, or none, which
// object() and the translator word in their own terms. Whether the
// names are in `shape` is object()'s alone, and whether a dictionary
// `additional` is a schema is the schema check's.
#let _object-problem(required-keys, dependent-required, additional) = {
  if not (additional in (none, false, true) or type(additional) == dictionary) {
    return _problem(
      "additional",
      "none, false, true, or a schema dict (built with the constructors)",
      repr(additional),
    )
  }
  // Checked whatever `additional` is: an open object reads the names as
  // keys too, so a non-string one would pass here and fail at validation.
  let p = _key-names-problem(required-keys, "required-keys")
  if p != none { return p }
  if type(dependent-required) != dictionary {
    return _problem(
      "dependent-required",
      "a dictionary of key to array of keys",
      repr(dependent-required),
    )
  }
  for (trigger, dependents) in dependent-required {
    let p = _key-names-problem(
      dependents,
      "dependent-required",
      entry: trigger,
    )
    if p != none { return p }
  }
}

// A leaf passes its `check`, constraint `family` and `model` (leaf.typ)
// instead of a walk. A walked kind passes its `family` too, when it
// takes constraint rows.
#let _kind(
  searchable: true,
  children: s => (),
  with-child: none,
  suffix: auto,
  inline: false,
  shorthand: s => none,
  bad-segment: (s, seg) => (
    message: "path segment "
      + repr(seg)
      + " cannot enter "
      + _a(s.kind)
      + " schema, which has no children.",
  ),
  walk: none,
  check: none,
  family: none,
  model: v => v,
  fields: (),
  problem: none,
) = (
  walk: if check != none { _leaf-walk(check, family, model) } else { walk },
  fields: fields,
  rows: _constraint-rows.filter(row => row.family == family),
  problem: problem,
  searchable: searchable,
  children: children,
  with-child: with-child,
  suffix: if suffix != auto { suffix } else if with-child == none {
    s => s.kind
  } else { s => none },
  inline: inline,
  shorthand: shorthand,
  bad-segment: bad-segment,
)

#let _kinds = (
  // A format and a pattern are fields on the node. The suffix names
  // the node as messages do (_kind-label), and a pattern gate of its
  // own (JSON Schema format + pattern) says so.
  string: _kind(
    check: _string-kind-check,
    family: "string",
    // Stored, a pattern and its message must be values: a null one
    // would reach `match` (string() leaves an unset one out).
    fields: (
      ("pattern", false, v => type(v) in (regex, str), "a regex or a string"),
      ("expected", false, v => type(v) == str, "a string"),
    ),
    problem: s => _as-field(_string-problem(
      format: s.at("format", default: none),
      pattern: s.at("pattern", default: none),
      expected: s.at("expected", default: none),
    )),
    suffix: s => (
      _kind-label(s) + if "pattern" in s { " + pattern" } else { "" }
    ),
  ),
  // The model wraps the string so it splices into markup.
  content: _kind(check: _string-check, family: "string", model: v => [#v]),
  number: _kind(check: _number-check, family: "number"),
  // A number with the integral gate; the number rows apply.
  integer: _kind(
    check: _integer-check,
    family: "number",
  ),
  bool: _kind(check: _bool-check),
  null: _kind(check: _null-check),
  any: _kind(check: _any-check),
  // The values inline, for at-a-glance debugging.
  enum: _kind(
    check: _enum-check,
    fields: (("values", true, v => type(v) == array, "an array of values"),),
    suffix: s => "enum (" + s.values.map(repr).join(", ") + ")",
  ),
  // find-paths only walks through the two plain containers: every
  // schema is full of them, so asking for one is more likely a slip
  // than a question.
  array: _kind(
    walk: _array-walk,
    family: "array",
    fields: (("elem", true, none, "a schema"),),
    searchable: false,
    inline: true,
    children: s => (("items", s.elem, "[]"),),
    with-child: (s, _, sub) => (..s, elem: sub),
    bad-segment: (s, seg) => _problem(
      "path segment",
      "\"items\" for an array schema",
      repr(seg),
    ),
  ),
  // Fields in key order, so every walk is diff-stable whatever order
  // the source declared them in; then the additional schema when it
  // is one. A field literally named "additionalProperties" shadows the
  // additional schema, as in lens paths: reach that through the parent.
  // A required field is labelled `name*`; the additional schema `*`,
  // the display-only key for "any other key".
  object: _kind(
    walk: _object-walk,
    fields: (
      (
        "shape",
        true,
        v => type(v) == dictionary,
        "a dictionary of field name to schema",
      ),
    ),
    // object() reads `additional: false` as none and stores neither, so
    // a node never holds false, which the walk would take for a schema.
    problem: s => if s.at("additional", default: none) == false {
      _problem(
        "field \"additional\"",
        "true or a schema (leave it out to reject other keys)",
        "false",
      )
    } else {
      _as-field(_object-problem(
        s.at("required-keys", default: ()),
        s.at("dependent-required", default: (:)),
        s.at("additional", default: none),
      ))
    },
    searchable: false,
    children: s => {
      let required = s.at("required-keys", default: ())
      let fields = s
        .shape
        .pairs()
        .sorted(key: p => p.at(0))
        .map(((k, sub)) => (k, sub, if k in required { k + "*" } else { k }))
      let additional = s.at("additional", default: none)
      // Shadowed by a literal "additionalProperties" field, the
      // additional schema has no lens segment (none): describe-schema
      // still draws it, but no path leads to it.
      let seg = if "additionalProperties" in s.shape { none } else {
        "additionalProperties"
      }
      if type(additional) == dictionary {
        fields + ((seg, additional, "*"),)
      } else { fields }
    },
    // As given: the lens write rebuilds it through object()
    // (traverse.typ), which sits above this registry.
    with-child: (s, seg, sub) => if seg in s.shape {
      // Typst dicts are values: this copy leaves `s` untouched.
      let shape = s.shape
      shape.insert(seg, sub)
      (..s, shape: shape)
    } else { (..s, additional: sub) },
    bad-segment: (s, seg) => if seg == "additionalProperties" {
      (
        message: "path segment \"additionalProperties\" needs the "
          + "object's `additional` to be a schema, got: "
          + repr(s.at("additional", default: none))
          + ".",
      )
    } else {
      (
        message: _not-in(
          "path segment " + repr(seg),
          "object shape",
          "Valid keys",
          s.shape.keys(),
        ),
      )
    },
  ),
  // A member's segment is its index, so a path doesn't say whether it
  // went through any-of or one-of.
  union: _kind(
    walk: _union-walk,
    fields: (
      (
        "members",
        true,
        v => type(v) == array and v != (),
        "a non-empty array of schemas",
      ),
      ("exclusive", true, v => type(v) == bool, "true or false"),
    ),
    children: s => s
      .members
      .enumerate()
      .map(((i, m)) => (i, m, "[" + str(i) + "]")),
    with-child: (s, i, sub) => {
      // Typst arrays are values: this copy leaves `s` untouched.
      let members = s.members
      members.at(i) = sub
      (..s, members: members)
    },
    bad-segment: (s, seg) => _problem(
      "path segment",
      "a member index, 0 to "
        + str(s.members.len() - 1)
        + ", for a union schema",
      repr(seg),
    ),
    // The header says which union; the members are listed below it.
    suffix: s => if s.exclusive { "one of" } else { "any of" },
    // `nullable(X)`, an any-of of exactly X then null, draws as `X?`.
    shorthand: s => if _is-nullable(s) { (of: s.members.first(), mark: "?") },
  ),
  "not": _kind(
    walk: _not-walk,
    fields: (("member", true, none, "a schema"),),
    // No header: the member's label, its lens segment, says it.
    children: s => (("not", s.member, "not"),),
    with-child: (s, _, sub) => (..s, member: sub),
    bad-segment: (s, seg) => _problem(
      "path segment",
      "\"not\" for a not schema",
      repr(seg),
    ),
  ),
  // The condition, then the branches it has. No header, as for `not`:
  // the labels, the lens segments, say what each child is.
  "if": _kind(
    walk: _if-walk,
    fields: (("cond", true, none, "a schema"),),
    children: s => _if-present(s).map(((seg, field)) => (
      seg,
      s.at(field),
      seg,
    )),
    with-child: (s, seg, sub) => {
      let (_, field) = _if-parts.find(((k, _)) => k == seg)
      (..s, (field): sub)
    },
    bad-segment: (s, seg) => _problem(
      "path segment",
      "one of "
        + _if-present(s).map(((k, _)) => repr(k)).join(", ")
        + " for an if schema",
      repr(seg),
    ),
  ),
)

// The descriptor of schema node `s`, which the entry points have checked
// (structure.typ's _require-schema), so its kind is registered.
#let _descriptor(s) = _kinds.at(s.kind)
