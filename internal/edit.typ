// Schema editing through schema paths.
//
// Top-level schema-* functions rather than methods on a record:
// Typst parses `dict.field(args)` as a type-method lookup, not a call
// of the closure stored under that key, so methods would force
// `(path.put)(args)` at every call site.
//
// The schema comes first everywhere, so edits pipe through `.fold`.
// Every function here points into the schema with a schema path, an
// array of segments.
//
// Path segments borrow JSON Schema keyword names (not the engine field
// names), but a schema path is not a JSON Schema location: a field is
// entered by its bare name, with no `properties` segment. Segments:
//   - object   : string key into `.shape`
//   - object   : literal "additionalProperties" to enter `.additional`
//                (only when set to a schema dict, not `true`)
//   - array    : literal "items" to enter `.elem`
//   - union    : int index into `.members` (any-of and one-of alike;
//                a nullable's schema is member 0)
//   - not      : literal "not" to enter `.member`
//   - if       : literal "if", "then" or "else" to enter `.cond`, `.then`
//                or `.otherwise` (a branch only when it is set)
//   - empty `()` : the whole schema
//
// Shape-first precedence for objects: if `"additionalProperties"` is
// both a literal property in `shape` and the additionalProperties
// keyword name, the literal property wins (meta-schemas are the
// realistic case where this collision arises). Reach the
// additional-schema in that rare collision case via schema-update on the
// parent — `p => p.additional` to read, `p => (..p, additional: new)`
// to write.
//
// Every edit keeps the constructors' invariants. The node `schema-put`
// writes, or `schema-update`'s function returns, must be a schema (checked
// whole, as every entry point checks one), and an edited object, the
// written node or any object above it, is rebuilt through object().
// Build replacements with the constructors.

#import "kinds/traverse.typ": _get-at, _set-at, _is-path, _schema-path
#import "kinds/structure.typ": (
  _require-schema, _has-kind, _is-object, _object-with, _rebuilt,
)
#import "kinds/walk.typ": _kind-label
#import "core/error.typ": (
  _a, _bail, _fail, _problem, _not-in, _require-bool, _require-key-names,
)

// A node entering from user code: a schema, and an object one rebuilt
// through object() so it can't break the constructor's invariants.
#let _checked(node, who) = {
  _require-schema(node, who)
  _rebuilt(node, who)
}

// What an argument is, for the order panic below.
#let _what(x) = if _has-kind(x) { "a schema" } else if _is-path(x) {
  "a path"
} else if x == none { "none" } else { _a(str(type(x))) }

// The schema and the path of a schema-get / schema-put / schema-update
// call. Given a schema first, the path is checked as the edits check
// theirs; anything else panics naming what came in which order. A
// malformed schema names the node at fault.
#let _subject(a, b, op) = {
  if _has-kind(a) {
    _require-schema(a, op + " schema")
    return (a, _schema-path(b, op))
  }
  _bail(
    op,
    "takes a schema, then a path (an array of segments); got "
      + _what(a)
      + " and "
      + _what(b)
      + ".",
  )
}

/// Reads the schema node at `at`. Panics if the path does not exist.
///
/// - schema (dictionary): The schema to read from.
/// - at (array): Where: a schema path.
/// -> dictionary
#let schema-get(schema, at) = {
  let (schema, path) = _subject(schema, at, "schema-get")
  _get-at(schema, path, "schema-get")
}

/// Returns a new schema with the node at `at` replaced by `value`. The
/// input schema is not changed. Panics if `value` is not a schema, or
/// if the edit breaks an object's invariants (as `object` would).
///
/// - schema (dictionary): The schema to edit.
/// - at (array): Where: a schema path.
/// - value (dictionary): The replacement node.
/// -> dictionary
#let schema-put(schema, at, value) = {
  let (schema, path) = _subject(schema, at, "schema-put")
  _set-at(schema, path, _checked(value, "schema-put value"), "schema-put")
}

/// Returns a new schema with the node at `at` replaced by `fn` applied
/// to it. Panics if `fn` is not a function or returns anything but a
/// schema, or if the edit breaks an object's invariants (as `object`
/// would).
///
/// - schema (dictionary): The schema to edit.
/// - at (array): Where: a schema path.
/// - fn (function): Takes the current node, returns the new one.
/// -> dictionary
#let schema-update(schema, at, fn) = {
  let (schema, path) = _subject(schema, at, "schema-update")
  if type(fn) != function {
    _fail("schema-update", _problem(
      "fn",
      "a function from the node to its replacement",
      repr(fn),
    ))
  }
  _set-at(
    schema,
    path,
    _checked(
      fn(_get-at(schema, path, "schema-update")),
      "schema-update result",
    ),
    "schema-update",
  )
}

// The skeleton the object edits share: check the schema and the
// path once, find the object at `at`, let `edit` check it and
// return the fields to change (as object() names them), and write it
// back rebuilt through object().
#let _edit-object(schema, at, op, edit) = {
  _require-schema(schema, op + " schema")
  let path = _schema-path(at, op)
  let parent = _get-at(schema, path, op)
  if not _is-object(parent) {
    _fail(op, _problem(
      "path",
      "an object schema",
      _a(_kind-label(parent)) + " schema",
    ))
  }
  // A hand-built object may leave `required-keys` out, as object() never
  // does: the edits read it with its default.
  let parent = (required-keys: (), ..parent)
  _set-at(schema, path, _object-with(parent, who: op, ..edit(parent)), op)
}

// A field's own schema path, as add-field and remove-field take it,
// split into the object's path and the field's name. Panics, naming
// `op`, unless it ends in a name.
#let _field-path(at, op) = {
  let at = _schema-path(at, op)
  if at == () or type(at.last()) != str {
    _fail(op, _problem(
      "path",
      "a field's path, ending in its name (a string)",
      repr(at),
    ))
  }
  (at.slice(0, -1), at.last())
}

// Collisions panic instead of overwriting silently — for the
// overwrite-an-existing-key case, callers can reach for schema-put /
// schema-update. `required: true` adds the key to required-keys in the
// same edit, so the object is rebuilt, and checked, once.
/// Returns a new schema with a field added at `at`, whose last segment
/// names it and whose rest is the object that gets it. Panics if that
/// is not an object or already has the key; use `schema-put` to replace
/// a field.
///
/// - schema (dictionary): The schema to edit.
/// - at (array): The new field's schema path, ending in its name.
/// - sub-schema (dictionary): The schema for the field.
/// - required (bool): Whether the object also requires the field.
/// -> dictionary
#let add-field(schema, at, sub-schema, required: false) = {
  _require-bool(required, "add-field", "required")
  let (at, key) = _field-path(at, "add-field")
  _edit-object(schema, at, "add-field", parent => {
    if key in parent.shape {
      _bail(
        "add-field",
        "key "
          + repr(key)
          + " already in object shape. "
          + "Use schema-put / schema-update to replace an existing field.",
      )
    }
    let edit = (shape: (..parent.shape, (key): sub-schema))
    if required and key not in parent.required-keys {
      edit.required-keys = parent.required-keys + (key,)
    }
    edit
  })
}

// The inverse of unset-required. On a closed object keys must exist
// in shape so a typo fails at edit time, not as a phantom "missing X"
// error; an open one allows what object() allows.
/// Returns a new schema where the object at `at` also requires `keys`,
/// after the keys it already requires. Panics if `keys` is not an array
/// of key names, or if a key is not in the shape of an object that
/// rejects other keys.
///
/// - schema (dictionary): The schema to edit.
/// - at (array): The object, as a schema path.
/// - keys (array): The fields to require.
/// -> dictionary
#let set-required(schema, at, keys) = {
  _require-key-names(keys, "set-required", "keys")
  _edit-object(schema, at, "set-required", parent => {
    let closed = parent.at("additional", default: none) == none
    let unknown = keys.filter(k => closed and k not in parent.shape)
    if unknown.len() > 0 {
      _bail("set-required", _not-in(
        "keys",
        "object shape",
        "Valid keys",
        parent.shape.keys(),
        names: unknown,
      ))
    }
    (required-keys: (parent.required-keys + keys).dedup())
  })
}

// Absent-key panics so a stale "still required" assumption surfaces.
/// Returns a new schema where the object at `at` no longer requires
/// `keys`. Panics if `keys` is not an array of key names, or if a key
/// was not required.
///
/// - schema (dictionary): The schema to edit.
/// - at (array): The object, as a schema path.
/// - keys (array): The fields to stop requiring.
/// -> dictionary
#let unset-required(schema, at, keys) = {
  _require-key-names(keys, "unset-required", "keys")
  _edit-object(schema, at, "unset-required", parent => {
    let absent = keys.filter(k => k not in parent.required-keys)
    if absent.len() > 0 {
      _bail("unset-required", _not-in(
        "keys",
        "required-keys",
        "Current required",
        parent.required-keys,
        names: absent,
      ))
    }
    (required-keys: parent.required-keys.filter(k => k not in keys))
  })
}

// Absent-key panics rather than being a silent no-op so caller typos surface.
/// Returns a new schema without the field at `at`, whose last segment
/// names it and whose rest is its object; the key also leaves the
/// object's required keys and dependent-required entries. Panics if
/// that is not an object or has no such key. A path from `find-paths`
/// that ends in a field name works as it is.
///
/// - schema (dictionary): The schema to edit.
/// - at (array): The field's schema path, ending in its name.
/// -> dictionary
#let remove-field(schema, at) = {
  let (at, key) = _field-path(at, "remove-field")
  _edit-object(schema, at, "remove-field", parent => {
    if key not in parent.shape {
      _bail("remove-field", _not-in(
        "key " + repr(key),
        "object shape",
        "Valid keys",
        parent.shape.keys(),
      ))
    }
    let shape = parent.shape
    let _ = shape.remove(key)
    // Like required-keys, drop `key` from every dependency: its own
    // trigger entry and its place in other triggers' lists. A trigger
    // left with no dependents goes too, and object() drops an empty map.
    let dependent = (:)
    for (trigger, dependents) in parent.at("dependent-required", default: (:)) {
      let kept = dependents.filter(d => d != key)
      if trigger != key and kept.len() > 0 {
        dependent.insert(trigger, kept)
      }
    }
    (
      shape: shape,
      required-keys: parent.required-keys.filter(k => k != key),
      dependent-required: dependent,
    )
  })
}
