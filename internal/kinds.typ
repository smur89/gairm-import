// Schema-kind constants and constructors. Lives in its own module
// because schema.typ depends on json-schema.typ (for derivation) and
// json-schema.typ depends on these primitives — extracting them here
// breaks the cycle.

/// A string, passed through as it is.
#let str-type = (kind: "str")
/// A string that the model returns as Typst `content`, so it splices into
/// markup.
#let content-type = (kind: "content")
/// An integer or a float.
#let number-type = (kind: "number")
/// A boolean.
#let bool-type = (kind: "bool")

// JSON Schema `integer`: any number with a zero fractional part
// (draft-7 semantics — 1.0 passes, 1.5 fails). Same "number" kind with
// a validation flag rather than a new kind, so coerce / introspect /
// lens need no extra branch.
/// A number with no fractional part. `1.0` passes and `1.5` fails.
#let integer-type = (kind: "number", integer: true)

// "Must be null or absent": `none` passes via the engine's global
// early return, non-none hits the kind branch and errors.
/// `null` or an absent key. Any other value is an error.
#let null-type = (kind: "null")

// Format-specialised string kinds — regex-gated in _validate;
// deliberately permissive (reject obvious malformations, not full RFC).
/// A string in ISO 8601 date form: `YYYY`, `YYYY-MM` or `YYYY-MM-DD`.
/// Data written in Typst may give a `datetime` with a date and no time;
/// it is checked and returned as the ISO string.
#let date-string = (kind: "date-string")
/// A string in ISO 8601 date and time form, `YYYY-MM-DDTHH:MM:SS`, with
/// an optional fraction and `Z` or `±HH:MM` offset. Data written in Typst
/// may give a `datetime` with a date and a time; it is checked and
/// returned as the ISO string.
#let datetime-string = (kind: "datetime-string")
/// A string that looks like a URI (a permissive check).
#let uri-string = (kind: "uri-string")
/// A string that looks like an email address (a permissive check).
#let email-string = (kind: "email-string")

// The format-gated kinds above as one list — validate.typ owns their
// regex table (keyed by these names, drift-guarded at load), coerce.typ
// passes them through as plain strings, introspect.typ lists them as
// leaf kinds. One list so adding a format kind is this line plus a
// regex, instead of three hand-synced module-local lists.
#let _format-string-kinds = (
  "date-string",
  "datetime-string",
  "uri-string",
  "email-string",
)

// Typst-native input for the date kinds (#134): a datetime of the
// right shape converts to the ISO string the kind's regex checks, so
// validate and coerce treat it exactly like the JSON string. Wrong
// shape returns none — a time is never dropped to make a date fit.
// Each kind maps to whether its datetime carries a time.
#let _datetime-kinds = ("date-string": false, "datetime-string": true)

#let _datetime-expected(kind) = (
  "a string or a datetime with a date and "
    + if _datetime-kinds.at(kind) { "a time" } else { "no time" }
)

#let _from-datetime(kind, value) = {
  let time = _datetime-kinds.at(kind)
  if value.year() != none and (value.hour() != none) == time {
    value.display(
      "[year]-[month]-[day]"
        + if time { "T[hour]:[minute]:[second]" } else { "" },
    )
  }
}

// Per-instance regex gate — a constructor, not a constant, because
// each schema node carries its own regex and hint.
/// A string that must match a regular expression. The match may be
/// anywhere in the string, so anchor the pattern with `^…$` for a
/// full match.
///
/// - re (regex, str): The pattern.
/// - expected (str): What the value should be, for the error message
///   ("expected …").
/// -> dictionary
#let pattern-string(re, expected: "matching pattern") = (
  kind: "pattern-string",
  pattern: if type(re) == regex { re } else { regex(re) },
  expected: expected,
)

/// An array whose every element matches `elem`.
///
/// - elem (dictionary): The schema for each element.
/// -> dictionary
#let array-of(elem) = (kind: "array", elem: elem)

// Mixed-type members allowed — the validator's `in` check gates on
// equality, not type. `const` is a singleton enum.
/// One of a fixed list of values. The values may be of mixed types.
///
/// - values (array): The allowed values.
/// -> dictionary
#let enum-of(values) = (kind: "enum", values: values)
/// Exactly one value. Same as `enum-of` with a single value.
///
/// - value (any): The only allowed value.
/// -> dictionary
#let const-of(value) = enum-of((value,))

// Bad-shape members fail at construction, not as a phantom validation
// error — same contract as object() below.
#let _require-members(fn-name, members) = {
  let ok = (
    type(members) == array
      and members.len() > 0
      and members.all(m => type(m) == dictionary and "kind" in m)
  )
  if not ok {
    panic(
      "gairm-import: "
        + fn-name
        + " members must be a non-empty array of schema dicts (each with a `kind` field); got: "
        + repr(members)
        + ".",
    )
  }
}

// JSON Schema anyOf / oneOf. Both share the union kind; `exclusive`
// distinguishes "at least one member matches" (any-of) from "exactly
// one" (one-of). Match counting lives in _validate; coerce delegates
// to the first matching member.
/// A value that matches at least one of the member schemas (JSON Schema
/// `anyOf`). Panics if `members` is empty or holds anything but schemas.
///
/// - members (array): The schemas to try.
/// -> dictionary
#let any-of(members) = {
  _require-members("any-of()", members)
  (kind: "union", members: members, exclusive: false)
}
/// A value that matches exactly one of the member schemas (JSON Schema
/// `oneOf`). Panics if `members` is empty or holds anything but schemas.
///
/// - members (array): The schemas to try.
/// -> dictionary
#let one-of(members) = {
  _require-members("one-of()", members)
  (kind: "union", members: members, exclusive: true)
}

// JSON Schema `not` — the value must NOT match the negated schema.
// Named not-of because `not` is a Typst keyword.
/// A value that must not match `member` (JSON Schema `not`). Panics if
/// `member` is not a schema.
///
/// - member (dictionary): The schema the value must fail.
/// -> dictionary
#let not-of(member) = {
  if not (type(member) == dictionary and "kind" in member) {
    panic(
      "gairm-import: not-of member must be a schema dict (with a `kind` field); got: "
        + repr(member)
        + ".",
    )
  }
  (kind: "not", member: member)
}

// `additional` controls keys not in `shape` (the engine-side name for
// JSON Schema's `additionalProperties`): `none` / `false` → reject;
// `true` → pass-through; schema dict → validate every extra against
// it. `false` is accepted as a synonym for `none` so callers fluent
// in JSON Schema can pass either. Bad-shape `additional` and
// required-keys-not-covered both fail at construction, not as a
// phantom validation error. `dependent-required` follows the same
// rule: a malformed map always panics, and trigger / dependent keys
// outside `shape` panic only when strict.
/// A dictionary with the fields in `shape`. Panics if `additional` is
/// the wrong shape, or, when `additional` is `none` or `false`, if
/// `required-keys` or `dependent-required` names a field not in `shape`.
///
/// - shape (dictionary): Field name to schema.
/// - required-keys (array): Fields that must be present.
/// - dependent-required (dictionary): Field name to the fields that must
///   also be present whenever it is.
/// - additional (none, bool, dictionary): What to do with keys not in
///   `shape`. `none` or `false` rejects them, `true` lets them through
///   unchecked, and a schema validates each one against it.
/// -> dictionary
#let object(
  shape,
  required-keys: (),
  dependent-required: (:),
  additional: none,
) = {
  // false ≡ none in our model; normalise so the constructor and the
  // translator agree on what they accept.
  let normalized = if additional == false { none } else { additional }
  let additional-ok = (
    normalized == none
      or normalized == true
      or (type(normalized) == dictionary and "kind" in normalized)
  )
  if not additional-ok {
    panic(
      "gairm-import: object() additional must be none, false, true, or a schema dict (with a `kind` field); got: "
        + repr(additional)
        + ".",
    )
  }
  // With `additional`, undeclared required keys are covered by the
  // additional schema, so the subset check only applies when strict.
  let unknown = if normalized == none {
    required-keys.filter(k => k not in shape)
  } else {
    ()
  }
  if unknown.len() > 0 {
    panic(
      "gairm-import: object() required-keys references keys not in shape: "
        + unknown.join(", ")
        + ".",
    )
  }
  if type(dependent-required) != dictionary {
    panic(
      "gairm-import: object() dependent-required must be a dictionary of key to array of keys; got: "
        + repr(dependent-required)
        + ".",
    )
  }
  for (trigger, dependents) in dependent-required {
    if type(dependents) != array or dependents.any(d => type(d) != str) {
      panic(
        "gairm-import: object() dependent-required for "
          + repr(trigger)
          + " must be an array of key names; got: "
          + repr(dependents)
          + ".",
      )
    }
  }
  let unknown-dependent = if normalized == none {
    dependent-required
      .pairs()
      .map(((trigger, dependents)) => (trigger,) + dependents)
      .flatten()
      .filter(k => k not in shape)
  } else {
    ()
  }
  if unknown-dependent.len() > 0 {
    panic(
      "gairm-import: object() dependent-required references keys not in shape: "
        + unknown-dependent.dedup().join(", ")
        + ".",
    )
  }
  let result = (
    kind: "object",
    shape: shape,
    required-keys: required-keys,
  )
  // Optional fields are omitted when empty / `none` so existing dicts
  // keep their shape.
  if dependent-required.len() > 0 {
    result.insert("dependent-required", dependent-required)
  }
  if normalized != none { result.insert("additional", normalized) }
  result
}

// An object that declares no fields and lets anything through is a
// free-form bag (JSON Resume's `custom`): opaque data, not a section
// with extras tacked on. Strict keeps it open, and coerce passes it
// through unchanged.
#let _is-free-form(schema) = (
  schema.kind == "object"
    and schema.shape.len() == 0
    and schema.at("additional", default: none) == true
)

// `required-keys` kwarg for symmetry with `object` — required keys
// on a pure map are still meaningful ("the document must contain
// these specific keys, plus any number of others").
/// A dictionary with any keys, whose values all match `value-schema`.
///
/// - value-schema (dictionary): The schema for every value.
/// - required-keys (array): Keys that must be present.
/// -> dictionary
#let map(value-schema, required-keys: ()) = object(
  (:),
  required-keys: required-keys,
  additional: value-schema,
)

// Each constructor beside the kind it builds, so paths-of-kind can
// take `pattern-string` as written in a schema. Functions compare by
// identity.
#let _constructor-kinds = (
  (pattern-string, "pattern-string"),
  (enum-of, "enum"),
  (const-of, "enum"),
  (any-of, "union"),
  (one-of, "union"),
  (not-of, "not"),
)
