// Every constraint row, end to end: its JSON keyword translates to its
// node field, and that node rejects some value with the row's code.
// Iterates the rows, so a new row is covered without editing this file
// (a new family needs a sample and failing values below).

#import "../internal/kinds/constraint.typ": _constraint-rows, _value-problem
#import "../lib.typ": validate, schema-from-json-schema

// A JSON Schema of each family to hang one keyword on.
#let base = (
  string: (type: "string"),
  number: (type: "number"),
  array: (type: "array", items: (type: "string")),
)

// Values among which each row's sample bound rejects at least one.
#let candidates = (
  string: ("", "abcdef"),
  number: (0, 3, 1.5),
  array: ((), ("a", "b", "c"), ("a", "a")),
)

#for row in _constraint-rows {
  // A keyword value the row accepts: a bound of 2, or a flag that's on.
  let sample = if _value-problem(row, 2) == none { 2 } else { true }
  let node = schema-from-json-schema(
    base.at(row.family) + ((row.json): sample),
  )
  assert.eq(
    node.at(row.field, default: none),
    sample,
    message: row.json + " should translate to " + row.field,
  )
  assert(
    candidates
      .at(row.family)
      .any(v => validate(v, schema: node).any(e => (
        e.code == row.code and e.path == ()
      ))),
    message: row.field + " should report code " + repr(row.code),
  )
}
