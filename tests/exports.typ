// The public surface: adding or removing an export must be a deliberate
// change to this list. lib.typ only re-exports public names, so a `*`
// import brings in nothing else.
#import "../lib.typ"

#let public = dictionary(lib).keys().sorted()
#assert.eq(public, (
  "add-field",
  "any-of",
  "any-type",
  "array-of",
  "bool-type",
  "coerce",
  "const-of",
  "content-type",
  "describe-schema",
  "enum-of",
  "format-errors",
  "if-of",
  "integer",
  "lens-get",
  "lens-over",
  "lens-put",
  "map",
  "not-of",
  "null-type",
  "nullable",
  "number",
  "object",
  "one-of",
  "parse",
  "path-to-pointer",
  "paths-of-kind",
  "pointer-to-path",
  "remove-field",
  "schema-from-json-schema",
  "set-required",
  "string",
  "unset-required",
  "validate",
))


// Every export is documented: the README covers the run functions and
// REFERENCE.md the rest, each as a whole name in backticks (`name`, or
// a call such as `name(..)`).
#let docs = read("../README.md") + read("../REFERENCE.md")
#for k in public {
  assert(
    docs.contains(regex("`" + k + "[`(]")),
    message: k + " is not in README.md or REFERENCE.md",
  )
}
