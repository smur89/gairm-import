// A path or bytes decodes as Typst's own json() does; anything else
// comes back as given, for the caller's type check. One place for the
// input forms parse and schema-from-json-schema share.
#let _decode-json(input) = if type(input) in (path, bytes) {
  json(input)
} else { input }
