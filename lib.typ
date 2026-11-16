// gairm-import: validate and coerce JSON data against a schema you
// bring (a JSON Schema document, or one built in Typst) into typed
// Typst values. This file is the
// package's only public surface; underscore names are internal.

#import "internal/kinds/leaf.typ": (
  number, integer, content-type, bool-type, null-type, any-type, enum-of,
  const-of,
)
#import "internal/kinds/format.typ": string
#import "internal/kinds/structure.typ" as _structure-mod
#import "internal/kinds/structure.typ": (
  array-of, object, map, any-of, one-of, not-of, if-of, nullable,
)
#import "internal/engine.typ" as _engine-mod
#import "internal/core/ctx.typ" as _ctx-mod
#import "internal/core/error.typ" as _error-mod
#import "internal/json-schema/translate.typ": schema-from-json-schema
#import "internal/core/input.typ" as _input-mod
#import "internal/lens.typ": (
  lens-get, lens-put, lens-over, add-field, remove-field, set-required,
  unset-required,
)
#import "internal/introspect.typ": describe-schema, paths-of-kind
#import "internal/core/pointer.typ": path-to-pointer, pointer-to-path

/// Turns a list of validation errors, as `validate` returns them, into
/// the combined report `parse` panics with. Use it when you handle the
/// errors yourself.
///
/// - errors (array): Records with at least `path` and `message`.
/// -> str
#let format-errors(errors) = _error-mod._format-report(errors)

/// Checks `data` against `schema` and returns every problem found, as
/// `(path, code, message, expected, got)` records; the README lists the
/// codes. An empty array means the data is valid.
///
/// - data (any): The document, or where to read it: a `path` or bytes
///   is read as JSON, and a `path` resolves from your file. Any other
///   value is the document itself, whatever root the schema takes. Null
///   panics, and so does a string ending in `.json` that the schema's
///   root does not take, as a string path would resolve from the
///   package: use `path(..)` or `json(..)` to read a file.
/// - schema (dictionary): The schema to check against. Required.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> array
#let validate(data, schema: none, strict-null: false) = {
  _structure-mod._require-schema(schema, "validate schema:")
  let value = _input-mod._decode-input("validate", data, str-is-data: true)
  let r = _engine-mod._walk(
    schema,
    value,
    _ctx-mod._ctx(strict-null: strict-null),
  )
  _input-mod._refuse-path("validate", data, r)
  r.errors
}

// Unknown keys are dropped silently rather than panicking, so direct
// callers who skip validation don't get a Typst dictionary-access
// panic.
/// Turns `data` into the typed model without checking it first, so run
/// `validate` before it. Keys the schema does not declare are dropped,
/// unless the object allows extras. Null values are dropped as absent
/// keys (unless `strict-null`); an object left with no keys stays an
/// empty dictionary.
///
/// - data (any): The document, or where to read it, as for `validate`.
/// - schema (dictionary): The schema that says what each field becomes.
///   Required.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> any
#let coerce(data, schema: none, strict-null: false) = {
  _structure-mod._require-schema(schema, "coerce schema:")
  let value = _input-mod._decode-input("coerce", data, str-is-data: true)
  let r = _engine-mod._walk(
    schema,
    value,
    _ctx-mod._ctx(strict-null: strict-null),
  )
  _input-mod._refuse-path("coerce", data, r)
  _engine-mod._coerce-result(r)
}

/// Validates `data` against `schema`, then coerces it into the typed
/// model. Panics with every problem found, so one compile shows them
/// all.
///
/// - data (any): The document, or where to read it, as for `validate`:
///   the root may be anything the schema takes, an array or a scalar
///   included.
/// - schema (dictionary): The schema to check against. Required.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> any
#let parse(data, schema: none, strict-null: false) = {
  _structure-mod._require-schema(schema, "parse schema:")
  let value = _input-mod._decode-input("parse", data, str-is-data: true)
  let r = _engine-mod._walk(
    schema,
    value,
    _ctx-mod._ctx(strict-null: strict-null),
  )
  _input-mod._refuse-path("parse", data, r)
  _engine-mod._parse-result(r)
}
