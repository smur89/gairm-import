// The public surface: adding or removing an export must be a deliberate
// change to this list. Underscore names are module aliases for internals,
// never values.
#import "../lib.typ"

#let public = (
  dictionary(lib).keys().filter(k => not k.starts-with("_")).sorted()
)
#assert.eq(public, (
  "add-field",
  "any-of",
  "any-type",
  "array-of",
  "bool-type",
  "coerce",
  "const-of",
  "content-type",
  "date-string",
  "datetime-string",
  "describe-schema",
  "email-string",
  "enum-of",
  "format-errors",
  "hostname-string",
  "if-of",
  "integer",
  "integer-type",
  "ipv4-string",
  "ipv6-string",
  "kind-at",
  "lens",
  "lens-get",
  "lens-over",
  "lens-put",
  "lens-then",
  "map",
  "not-of",
  "null-type",
  "nullable",
  "number",
  "number-type",
  "object",
  "one-of",
  "parse",
  "path-to-pointer",
  "paths-of-kind",
  "pattern-string",
  "pointer-to-path",
  "remove-field",
  "resume-schema",
  "resume-schema-strict",
  "schema-from-json-schema",
  "set-required",
  "str-type",
  "string",
  "time-string",
  "unset-required",
  "uri-string",
  "uuid-string",
  "validate",
))

#for (k, v) in dictionary(lib) {
  if k.starts-with("_") {
    assert.eq(type(v), module, message: k + " leaks a private value")
  }
}

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
