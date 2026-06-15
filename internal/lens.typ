// Lens-style schema editing. A lens is a path-carrying value;
// `lens-get` / `lens-put` / `lens-over` / `lens-then` are the
// operations. Top-level functions rather than dict-methods because
// Typst parses `dict.field(args)` as "method on the dict type", not
// "call the closure stored under that field" — pulling the operations
// out keeps call sites readable.
//
// Path segments:
//   - object: string key into `.shape`
//   - array : the literal "items" to enter `.elem`
//   - empty `()` : identity lens (get returns the schema unchanged,
//     put replaces it wholesale)
//
// All operations are functional — they return a NEW schema and leave
// the input untouched. Errors at invalid paths panic with the bad
// segment, the schema kind we were on, and the keys that would have
// been valid, so a typo in a long path surfaces a useful diagnostic
// instead of "key not in dict".

#let _bail(msg) = panic("json-resume: " + msg)

#let _descend(schema, segment) = {
  if schema.kind == "object" {
    if segment not in schema.shape {
      _bail(
        "lens path segment " + repr(segment) + " not in object shape. " +
          "Valid keys: " + schema.shape.keys().join(", ") + ".",
      )
    }
    return schema.shape.at(segment)
  }
  if schema.kind == "array" {
    if segment != "items" {
      _bail(
        "lens segment for an array schema must be \"items\", got " +
          repr(segment) + ".",
      )
    }
    return schema.elem
  }
  _bail(
    "lens cannot descend into a leaf schema (kind=" + repr(schema.kind) +
      ") with segment " + repr(segment) + ".",
  )
}

#let _get-at(schema, path) = {
  let cursor = schema
  for segment in path { cursor = _descend(cursor, segment) }
  cursor
}

// Rebuild the schema by walking the path with _descend (so an invalid
// segment surfaces the same diagnostic as a get), then rebuilding
// outward from the leaf with the replacement value.
#let _set-at(schema, path, value) = {
  if path.len() == 0 { return value }
  let cursors = (schema,)
  for segment in path { cursors.push(_descend(cursors.last(), segment)) }
  let new = value
  let i = path.len()
  while i > 0 {
    i -= 1
    let parent = cursors.at(i)
    let segment = path.at(i)
    if parent.kind == "object" {
      let new-shape = parent.shape
      new-shape.insert(segment, new)
      new = (..parent, shape: new-shape)
    } else {
      new = (..parent, elem: new)
    }
  }
  new
}

// Lens-as-value. The lens itself only carries a path; operations are
// the top-level lens-* functions below.
#let lens(path) = (kind: "lens", path: path)

#let lens-get(l, schema) = _get-at(schema, l.path)

// `lens-put` is the lens-`set` operation. Named `put` because `set` is
// a Typst keyword and can't appear as a function name in this position.
#let lens-put(l, schema, value) = _set-at(schema, l.path, value)

#let lens-over(l, schema, fn) = _set-at(schema, l.path, fn(_get-at(schema, l.path)))

// Composition: paths concatenate. `lens-then(a, b)` first applies a,
// then b — the same as constructing a single lens with the joined path.
#let lens-then(a, b) = lens(a.path + b.path)

// Add a key to the object schema targeted by `parent-lens`. Panics if
// the target is not an object schema, or if the key is already there
// (additive intent — collisions would silently overwrite via lens-over).
#let add-field(schema, parent-lens, key, sub-schema) = lens-over(
  parent-lens,
  schema,
  parent => {
    if parent.kind != "object" {
      _bail(
        "add-field expects an object schema at the lens target, " +
          "got kind=" + repr(parent.kind) + ".",
      )
    }
    if key in parent.shape {
      _bail(
        "add-field key " + repr(key) + " already in object shape. " +
          "Use lens-put / lens-over to replace an existing field.",
      )
    }
    let new-shape = parent.shape
    new-shape.insert(key, sub-schema)
    (..parent, shape: new-shape)
  },
)

// Inverse of add-field. Panics if the target is not an object or the
// key is absent — no silent no-op, so caller typos surface.
#let remove-field(schema, parent-lens, key) = lens-over(
  parent-lens,
  schema,
  parent => {
    if parent.kind != "object" {
      _bail(
        "remove-field expects an object schema at the lens target, " +
          "got kind=" + repr(parent.kind) + ".",
      )
    }
    if key not in parent.shape {
      _bail(
        "remove-field key " + repr(key) + " not in object shape. " +
          "Valid keys: " + parent.shape.keys().join(", ") + ".",
      )
    }
    let new-shape = parent.shape
    let _ = new-shape.remove(key)
    let new-required = parent.required-keys.filter(k => k != key)
    (..parent, shape: new-shape, required-keys: new-required)
  },
)
