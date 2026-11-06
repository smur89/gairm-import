// The input forms every entry point shares. A string panics with the
// path(..) hint (#132: inside a package it resolves from the package
// root); a path or bytes decodes as json() does; null is rejected; any
// other value is returned for the caller's own type rule.
//
// `str-is-data` is for validate and coerce, whose root may legitimately
// be a string (a scalar schema such as date-string); a string then
// passes through as the value instead of panicking as a path.
#import "error.typ": _bail

#let _decode-input(fn-name, data, str-is-data: false) = {
  if type(data) == str and not str-is-data {
    _bail(
      fn-name,
      "does not take a string path: inside a "
        + "package it resolves from the package, not your project. Pass path("
        + repr(data)
        + ") or json("
        + repr(data)
        + ") instead.",
    )
  }
  let value = if type(data) in (path, bytes) { json(data) } else { data }
  if value == none { _bail(none, "input must be a dict, got null.") }
  value
}
