// The constraint keywords, one row each. A row ties a node field to
// its JSON Schema keyword, the family of values it applies to, the
// error code a miss reports, and which raw keyword values the
// translator accepts. A bound (`op`) is checked against the family's
// measure; the two keywords that are not bounds carry a `test`. The
// engine, the translator's reader, its allow-list and its enum/const
// fold all read these rows, so a new keyword is one row.

// Which raw values a keyword takes, as checks run in order; the first
// that fails names what the value must be.
#let _count = (
  (ok: v => type(v) == int and v >= 0, must: "a non-negative integer"),
)
#let _number = ((ok: v => type(v) in (int, float), must: "a number"),)
#let _positive = _number + ((ok: v => v > 0, must: "> 0"),)
#let _flag = ((ok: v => type(v) == bool, must: "a boolean"),)

// What a bound measures in each family, and how a message names it.
// Strings count clusters, not bytes — JSON Schema talks "length"
// without pinning. Arrays skip `none`: coerce drops them, so raw counts
// would validate inputs whose rendered model violates min-items.
#let _measures = (
  string: (label: "string length ", of: v => v.clusters().len()),
  number: (label: "", of: v => v),
  array: (label: "array length ", of: v => v.filter(e => e != none).len()),
)

#let _holds = (
  "≥": (n, bound) => n >= bound,
  "≤": (n, bound) => n <= bound,
  ">": (n, bound) => n > bound,
  "<": (n, bound) => n < bound,
)

// Integers stay exact; floats compare the ratio with a tolerance, since
// calc.rem(0.3, 0.1) is not 0.
#let _multiple-test(mult, value) = {
  // A schema bug, not a data error: the translator rejects it, but a
  // hand-built node can carry it.
  if mult <= 0 {
    panic(
      "gairm-import: multiple-of must be positive, got " + str(mult) + ".",
    )
  }
  let off = if type(value) == int and type(mult) == int {
    calc.rem(value, mult) != 0
  } else {
    let q = value / mult
    calc.abs(q - calc.round(q)) >= 1e-9
  }
  if off {
    (
      message: "expected multiple of "
        + str(mult)
        + ", got "
        + str(value)
        + ".",
      expected: (multiple-of: mult),
      got: value,
    )
  }
}

// A value as coerce's null-as-absent rule leaves it: null keys and
// null elements removed at every depth. Uniqueness compares these, or
// items differing only by a null key would pass and then coerce to
// duplicates.
#let _strip-nulls(value) = {
  if type(value) == dictionary {
    value
      .pairs()
      .filter(((_, v)) => v != none)
      .map(((k, v)) => (k, _strip-nulls(v)))
      .to-dict()
  } else if type(value) == array {
    value.filter(v => v != none).map(_strip-nulls)
  } else { value }
}

// The first duplicate only, cited by original positions (nulls
// skipped) so callers can find it.
#let _unique-test(on, value) = {
  if not on { return none }
  let present = value.enumerate().filter(((_, elem)) => elem != none)
  let stripped = present.map(((_, elem)) => _strip-nulls(elem))
  for i in range(present.len()) {
    for j in range(i + 1, present.len()) {
      if stripped.at(i) == stripped.at(j) {
        let orig-i = present.at(i).at(0)
        let orig-j = present.at(j).at(0)
        return (
          message: "expected unique items, duplicate at indices "
            + str(orig-i)
            + " and "
            + str(orig-j)
            + ".",
          expected: none,
          got: (orig-i, orig-j),
        )
      }
    }
  }
  none
}

// Within a family, rows run in this order, so errors and translator
// diagnostics come out in it.
#let _constraint-rows = (
  (
    field: "min-length",
    json: "minLength",
    family: "string",
    code: "length",
    accepts: _count,
    op: "≥",
  ),
  (
    field: "max-length",
    json: "maxLength",
    family: "string",
    code: "length",
    accepts: _count,
    op: "≤",
  ),
  (
    field: "minimum",
    json: "minimum",
    family: "number",
    code: "range",
    accepts: _number,
    op: "≥",
  ),
  (
    field: "maximum",
    json: "maximum",
    family: "number",
    code: "range",
    accepts: _number,
    op: "≤",
  ),
  (
    field: "exclusive-minimum",
    json: "exclusiveMinimum",
    family: "number",
    code: "range",
    accepts: _number,
    op: ">",
  ),
  (
    field: "exclusive-maximum",
    json: "exclusiveMaximum",
    family: "number",
    code: "range",
    accepts: _number,
    op: "<",
  ),
  (
    field: "multiple-of",
    json: "multipleOf",
    family: "number",
    code: "multiple",
    accepts: _positive,
    test: _multiple-test,
  ),
  (
    field: "min-items",
    json: "minItems",
    family: "array",
    code: "items",
    accepts: _count,
    op: "≥",
  ),
  (
    field: "max-items",
    json: "maxItems",
    family: "array",
    code: "items",
    accepts: _count,
    op: "≤",
  ),
  (
    field: "unique-items",
    json: "uniqueItems",
    family: "array",
    code: "unique",
    accepts: _flag,
    test: _unique-test,
  ),
)

#let _constraints = _constraint-rows.map(row => (row.field, row)).to-dict()

// Lower / upper pairs that must leave a satisfying value; `strict`
// pairs (an exclusive bound on either side) may not even meet.
#let _bound-pairs = (
  (lower: "min-length", upper: "max-length", strict: false),
  (lower: "minimum", upper: "maximum", strict: false),
  (lower: "exclusive-minimum", upper: "maximum", strict: true),
  (lower: "minimum", upper: "exclusive-maximum", strict: true),
  (lower: "exclusive-minimum", upper: "exclusive-maximum", strict: true),
  (lower: "min-items", upper: "max-items", strict: false),
)

/// What a raw keyword value must be, if `value` is not one the row
/// accepts; none if it is.
#let _value-problem(row, value) = {
  let failed = row.accepts.find(check => not (check.ok)(value))
  if failed != none { failed.must }
}

/// The first pair on `node` that no value can satisfy, or none. Callers
/// word the diagnostic themselves.
#let _bounds-conflict(node) = _bound-pairs.find(pair => {
  let lower = node.at(pair.lower, default: none)
  let upper = node.at(pair.upper, default: none)
  (
    lower != none
      and upper != none
      and not if pair.strict { lower < upper } else { lower <= upper }
  )
})

/// How `value` misses the row's constraint `bound`, as the error's
/// `(message, expected, got)`, or none when it holds.
#let _constraint-miss(row, bound, value) = {
  if "test" in row { return (row.test)(bound, value) }
  let measure = _measures.at(row.family)
  let n = (measure.of)(value)
  if not (_holds.at(row.op))(n, bound) {
    (
      message: "expected "
        + measure.label
        + row.op
        + " "
        + str(bound)
        + ", got "
        + str(n)
        + ".",
      expected: ((row.field): bound),
      got: n,
    )
  }
}
