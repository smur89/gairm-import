// Error-formatting helpers. `_format-path` renders a path tuple as a
// readable string; `_format-report` joins a list of errors into one
// panic-ready message; `_type-name-of` maps a value's Typst type to a
// friendlier JSON-ish name for error messages.

// Path-tuple → readable string. Strings join with ".", integers
// render as "[i]". Empty path renders as "<root>" so a top-level
// type error reads `"<root>: expected object, got …"`.
#let _format-path(parts) = {
  if parts.len() == 0 { return "<root>" }
  parts.enumerate().map(((i, part)) => {
    if type(part) == int { "[" + str(part) + "]" }
    else if i == 0 { part }
    else { "." + part }
  }).join("")
}

// Typst's `repr(type(value))` renders as `"int"`, `"dictionary"`,
// `"type(none)"`, etc. — accurate but jarring in user-facing
// messages. This map translates the common ones into JSON-Resume-
// shaped names so a panic reads `"got integer"` / `"got object"` /
// `"got null"` instead. Unknown reprs fall through unchanged.
#let _type-names = (
  str: "string",
  int: "integer",
  float: "number",
  bool: "boolean",
  array: "array",
  dictionary: "object",
)

#let _type-name-of(value) = {
  if value == none { return "null" }
  let raw = repr(type(value))
  _type-names.at(raw, default: raw)
}

// Renders a list of {path, message} errors into a single
// human-readable string suitable for `panic(...)`.
#let _format-report(errors) = {
  let n = errors.len()
  let noun = if n == 1 { "problem" } else { "problems" }
  let lines = errors.map(e => "  - " + _format-path(e.path) + ": " + e.message)
  "json-resume: found " + str(n) + " " + noun + " in the input:\n" + lines.join("\n")
}
