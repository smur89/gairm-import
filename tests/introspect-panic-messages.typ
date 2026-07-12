// Source-level pin pattern — see tests/lens-panic-messages.typ for
// the basic shape and tests/json-schema-panic-messages.typ for the
// coverage + substring rules.

#let src = read("../internal/introspect.typ")

// `paths-of-kind` leaf-kind guard. First pin includes the prefix so
// a regression to the pre-rename `json-resume:` form fails loud;
// the second can't take the prefix without spanning a source-line
// break (the message is split across two `+ "..."` chunks).
#assert(src.contains("gairm-import: paths-of-kind kind-name"))
#assert(src.contains("not a recognised leaf kind"))
