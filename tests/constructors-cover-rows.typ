// The constructors' named arguments and the constraint rows list the
// same fields. Each row's family constructor is called with the row's
// field as a named argument: Typst rejects an unexpected one, so a row
// missing from a signature fails here, and a parameter the body drops
// leaves the field unset and fails the comparison with the translator.
// Iterates the rows, so a new row is covered without editing this file
// (a new family needs its constructors below).

#import "../internal/kinds/constraint.typ": _constraint-rows
#import "../lib.typ": (
  string, number, integer, array-of, str-type, schema-from-json-schema,
)

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
