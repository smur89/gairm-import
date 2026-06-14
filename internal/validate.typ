// Pure validator. Returns a flat list of {path, message} records for
// every shape/type mismatch found. Empty list = valid. Path is a tuple
// of dict keys and array indices; rendering lives in errors.typ.
//
// Note: when a key is unknown, the unknown-key error is reported but
// its subtree is not walked — the subtree's expected shape is, by
// definition, undefined.

#import "errors.typ": _type-name-of

#let _type-error(path, expected, value) = ((
  path: path,
  message: "expected " + expected + ", got " + _type-name-of(value) + ".",
),)

#let _validate(schema, value, path) = {
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
    let valid-keys-str = schema.shape.keys().join(", ")
    return value.pairs().map(((key, sub-value)) => {
      if key in schema.shape {
        _validate(schema.shape.at(key), sub-value, path + (key,))
      } else {
        ((
          path: path + (key,),
          message: "unknown key " + repr(key) + ". Valid keys: " + valid-keys-str + ".",
        ),)
      }
    }).flatten()
  }
  panic("json-resume: internal — unknown schema kind " + repr(kind))
}
