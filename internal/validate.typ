// Subtrees under unknown keys are not walked — their expected shape
// is undefined.
//
// JSON `null` (Typst's `none`) at a value position is treated as if
// the key were absent: no type error, no recursion. Per-key null
// values in objects are skipped in the recursion loop; null array
// elements are absorbed by the top-of-function early return. See
// README "Errors" section for the user-facing rationale.

#import "errors.typ": _type-name-of

#let _type-error(path, expected, value) = ((
  path: path,
  message: "expected " + expected + ", got " + _type-name-of(value) + ".",
),)

#let _validate(schema, value, path) = {
  // Null at any value position is "key absent" — no error, no
  // recursion. This handles array elements via the per-element call
  // and standalone scalar invocations; per-key null values in object
  // shapes are also short-circuited inside the object branch.
  if value == none { return () }
  let kind = schema.kind
  if kind in ("str", "content") {
    if type(value) != str { return _type-error(path, "string", value) }
    return ()
  }
  if kind == "number" {
    if type(value) not in (int, float) { return _type-error(path, "number", value) }
    return ()
  }
  if kind == "array" {
    if type(value) != array { return _type-error(path, "array", value) }
    return value.enumerate()
      .map(((i, elem)) => _validate(schema.elem, elem, path + (i,)))
      .flatten()
  }
  if kind == "object" {
    if type(value) != dictionary { return _type-error(path, "object", value) }
    let per-key-errs = value.pairs().map(((key, sub-value)) => {
      if key in schema.shape {
        // A known key with an explicit null value is treated as
        // absent — no recursion, no error.
        if sub-value == none { () }
        else { _validate(schema.shape.at(key), sub-value, path + (key,)) }
      } else {
        // Valid-keys list only assembled on the unknown-key branch so
        // the happy path skips the join. An unknown key with a null
        // value is still flagged — silently swallowing typos would
        // defeat the point of strict validation.
        let valid-keys-str = schema.shape.keys().join(", ")
        ((
          path: path + (key,),
          message: "unknown key " + repr(key) + ". Valid keys: " + valid-keys-str + ".",
        ),)
      }
    }).flatten()
    let required = schema.at("required-keys", default: ())
    // A required key whose value is explicit null counts as missing —
    // null-as-absent applies uniformly, including to the missing-
    // required check.
    let missing-errs = required
      .filter(k => k not in value or value.at(k) == none)
      .map(k => (
        path: path + (k,),
        message: "missing required key " + repr(k) + ".",
      ))
    return per-key-errs + missing-errs
  }
  panic("json-resume: internal — unknown schema kind " + repr(kind))
}
