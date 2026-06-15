// Empty path renders as "<root>" so a top-level type error reads
// `"<root>: expected object, got …"`.
#let _format-path(parts) = {
  if parts.len() == 0 { return "<root>" }
  parts.enumerate().map(((i, part)) => {
    if type(part) == int { "[" + str(part) + "]" }
    else if i == 0 { part }
    else { "." + part }
  }).join("")
}

// Typst's `repr(type(...))` renders as `"int"` / `"dictionary"` /
// `"type(none)"` — accurate but jarring. Translate to JSON-shaped
// names for user-facing messages; unknown reprs fall through.
#let _type-names = (
  str: "string",
  int: "integer",
  float: "number",
  bool: "boolean",
  array: "array",
  dictionary: "object",
)

// The `none` branch is defensive: the validator's null-as-absent rule
// means _type-error never sees a null value today, but _type-name-of is
// a general helper that may be reused by future code paths.
#let _type-name-of(value) = {
  if value == none { return "null" }
  let raw = repr(type(value))
  _type-names.at(raw, default: raw)
}

#let _format-report(errors) = {
  let n = errors.len()
  let noun = if n == 1 { "problem" } else { "problems" }
  let lines = errors.map(e => "  - " + _format-path(e.path) + ": " + e.message)
  "gairm-import: found " + str(n) + " " + noun + " in the input:\n" + lines.join("\n")
}

// Classic two-row Levenshtein edit distance. We fold over the
// characters of `a`, carrying the previous DP row and producing the
// next. Each new row is itself built by folding over the characters
// of `b`, since cell `(i, j)` depends on `(i-1, j)`, `(i, j-1)` and
// `(i-1, j-1)`. The base row is `0..n` (cost of deleting `j` chars
// from `b` to reach the empty prefix of `a`).
#let _edit-distance(a, b) = {
  let ac = a.clusters()
  let bc = b.clusters()
  let n = bc.len()
  let base-row = range(0, n + 1)
  let final-row = ac.enumerate().fold(base-row, (prev, pair) => {
    let (i, ca) = pair
    bc.enumerate().fold((i + 1,), (row, pair2) => {
      let (j, cb) = pair2
      let cost = if ca == cb { 0 } else { 1 }
      let deletion = prev.at(j + 1) + 1
      let insertion = row.at(j) + 1
      let substitution = prev.at(j) + cost
      row + (calc.min(deletion, insertion, substitution),)
    })
  })
  final-row.at(n)
}

// Pure: rank candidates by edit distance, return the closest one
// inside `max-distance`. Empty `candidates` → none. Ties resolved by
// `sorted`'s stable order (i.e. input order).
#let _closest-match(target, candidates, max-distance) = {
  let ranked = candidates
    .map(c => (key: c, distance: _edit-distance(target, c)))
    .sorted(key: e => e.distance)
  let best = ranked.at(0, default: none)
  if best == none { return none }
  if best.distance <= max-distance { best.key } else { none }
}
