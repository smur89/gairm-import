// gairm-import: validate and coerce JSON data (JSON Resume by default,
// or your own JSON Schema) into typed Typst values. This file is the
// package's only public surface; underscore names are internal.

#import "internal/kinds/leaf.typ": (
  str-type, content-type, number-type, integer-type, bool-type, null-type,
  any-type, pattern-string, enum-of, const-of,
)
#import "internal/kinds/format.typ": (
  date-string, datetime-string, uri-string, email-string, uuid-string,
  hostname-string, ipv4-string, ipv6-string, time-string,
)
#import "internal/kinds/structure.typ": (
  array-of, object, map, any-of, one-of, not-of, nullable,
)
#import "internal/schema.typ": resume-schema, resume-schema-strict
#import "internal/engine.typ" as _engine-mod
#import "internal/core/ctx.typ" as _ctx-mod
#import "internal/core/error.typ" as _error-mod
#import "internal/json-schema.typ": schema-from-json-schema
#import "internal/core/input.typ" as _input-mod
#import "internal/lens.typ": (
  lens, lens-get, lens-put, lens-over, lens-then, add-field, remove-field,
  set-required, unset-required,
)
#import "internal/introspect.typ": describe-schema, paths-of-kind, kind-at
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
/// - data (dictionary, path, bytes): The document, or where to read it.
///   A `path` resolves from your file. A string is the value itself (a
///   scalar schema checks it), never a path; use `path(..)` or
///   `json(..)` to read a file. Null panics.
/// - schema (dictionary): The schema to check against.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> array
#let validate(data, schema: resume-schema, strict-null: false) = {
  let value = _input-mod._decode-input("validate", data, str-is-data: true)
  _engine-mod
    ._walk(schema, value, _ctx-mod._ctx(strict-null: strict-null))
    .errors
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
/// - data (dictionary, path, bytes): The document, or where to read it.
///   A `path` resolves from your file. A string is the value itself (a
///   scalar schema converts it), never a path; use `path(..)` or
///   `json(..)` to read a file. Null panics.
/// - schema (dictionary): The schema that says what each field becomes.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> dictionary
#let coerce(data, schema: resume-schema, strict-null: false) = {
  let value = _input-mod._decode-input("coerce", data, str-is-data: true)
  _engine-mod._coerce-result(_engine-mod._walk(
    schema,
    value,
    _ctx-mod._ctx(strict-null: strict-null),
  ))
}

/// Validates `data` against `schema`, then coerces it into the typed
/// model. Panics with every problem found, so one compile shows them
/// all.
///
/// - data (dictionary, path, bytes): The document, or where to read it.
///   A `path` resolves from your file. A `str` panics, because inside a
///   package it would resolve from the package; use `path(..)` or
///   `json(..)` instead.
/// - schema (dictionary): The schema to check against.
/// - strict-null (bool): Off, JSON `null` counts as an absent key. On,
///   `null` is a value: only `null-type` and `nullable(..)` accept it.
/// -> dictionary
#let parse(data, schema: resume-schema, strict-null: false) = {
  let dict-data = _input-mod._decode-input("parse", data)
  if type(dict-data) != dictionary {
    panic(
      "gairm-import: parse expected a dict, a path, or bytes, got "
        + repr(type(dict-data))
        + ".",
    )
  }
  _engine-mod._parse-result(_engine-mod._walk(
    schema,
    dict-data,
    _ctx-mod._ctx(strict-null: strict-null),
  ))
}
