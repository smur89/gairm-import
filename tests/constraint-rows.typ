// Every constraint row, end to end. Both checks iterate the rows, so a
// new row is covered without editing this file (a new family needs a
// sample, failing values and its constructors below).

#import "../internal/kinds/constraint.typ": _constraint-rows, _value-problem
#import "../lib.typ": (
  validate, schema-from-json-schema, string, number, integer, array-of,
  str-type,
)

// ---- the translator and validate -------------------------------------------
//
// Each row's JSON keyword translates to its node field, and that node
// rejects some value with the row's code.

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

// ---- the constructors --------------------------------------------------------
//
// The constructors' named arguments and the rows list the same fields.
// Each row's family constructor is called with the row's field as a
// named argument: Typst rejects an unexpected one, so a row missing from
// a signature fails here, and a parameter the body drops leaves the
// field unset and fails the comparison with the translator.

// Per family, each constructor that takes its rows, with the JSON
// Schema the translator builds the same node from.
#let constructors = (
  string: ((build: args => string(..args), js: (type: "string")),),
  number: (
    (build: args => number(..args), js: (type: "number")),
    (build: args => integer(..args), js: (type: "integer")),
  ),
  array: (
    (
      build: args => array-of(str-type, ..args),
      js: (type: "array", items: (type: "string")),
    ),
  ),
)

// A value every row of a family accepts (a flag row takes `true`).
#let sample(row) = if row.field == "unique-items" { true } else { 2 }

#for row in _constraint-rows {
  for c in constructors.at(row.family) {
    let built = (c.build)(((row.field): sample(row)))
    assert.eq(
      built,
      schema-from-json-schema((..c.js, (row.json): sample(row))),
      message: row.field + " on " + repr(c.js),
    )
    assert(row.field in built, message: row.field + " left unset")
  }
}
