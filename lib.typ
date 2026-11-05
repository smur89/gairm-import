// Strict loader for canonical JSON Resume data
// (https://jsonresume.org/schema). The engines under internal/ are
// pure functions of (schema, value); see
// tests/engine-schema-agnostic.typ for the BYO-schema contract.

#import "internal/kinds.typ": (
  str-type, content-type, number-type, integer-type, bool-type, null-type,
  array-of, object, map, date-string, datetime-string, uri-string, email-string,
  uuid-string, hostname-string, ipv4-string, ipv6-string, time-string,
  pattern-string, enum-of, const-of, any-of, one-of, not-of,
)
#import "internal/schema.typ": resume-schema, resume-schema-strict
#import "internal/validate.typ": _validate
#import "internal/coerce.typ": _coerce
#import "internal/errors.typ": _format-report
#import "internal/json-schema.typ": schema-from-json-schema
#import "internal/decode.typ": _decode-json
#import "internal/lens.typ": (
  lens, lens-get, lens-put, lens-over, lens-then, add-field, remove-field,
  set-required, unset-required,
)
#import "internal/introspect.typ": describe-schema, paths-of-kind, kind-at
#import "internal/json-pointer.typ": path-to-pointer, pointer-to-path

// Engines treat `none` at any value position as "key absent" — right
// for leaves inside a document, but a null root is always invalid
// (no schema can validate "missing document"). One source of truth
// for the message so docs and tests have something stable to pin.
#let _reject-none-root(data) = {
  if data == none { panic("gairm-import: input must be a dict, got null.") }
}

/// Turns a list of validation errors, as `validate` returns them, into
/// the combined report `parse` panics with. Use it when you handle the
/// errors yourself.
///
/// - errors (array): `(path, message)` records.
/// -> str
#let format-errors(errors) = _format-report(errors)

/// Checks `data` against `schema` and returns every problem found. An
/// empty array means the data is valid.
///
/// - data (dictionary): The document to check.
/// - schema (dictionary): The schema to check against.
/// -> array
#let validate(data, schema: resume-schema) = {
  _reject-none-root(data)
  _validate(schema, data, ())
}

// Unknown keys are dropped silently rather than panicking, so direct
// callers who skip validation don't get a Typst dictionary-access
// panic.
/// Turns `data` into the typed model without checking it first, so run
/// `validate` before it. Keys the schema does not declare are dropped,
/// unless the object allows extras.
///
/// - data (dictionary): The document to convert.
/// - schema (dictionary): The schema that says what each field becomes.
/// -> dictionary
#let coerce(data, schema: resume-schema) = {
  _reject-none-root(data)
  _coerce(schema, data)
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
/// -> dictionary
#let parse(data, schema: resume-schema) = {
  if type(data) == str {
    panic(
      "gairm-import: parse does not take a string path: inside a "
        + "package it resolves from the package, not your project. "
        + "Pass path("
        + repr(data)
        + ") or json("
        + repr(data)
        + ") instead.",
    )
  }
  let dict-data = _decode-json(data)
  _reject-none-root(dict-data)
  if type(dict-data) != dictionary {
    panic(
      "gairm-import: parse expected a dict, a path, or bytes, got "
        + repr(type(dict-data))
        + ".",
    )
  }
  let errors = _validate(schema, dict-data, ())
  if errors.len() > 0 { panic(format-errors(errors)) }
  _coerce(schema, dict-data)
}
