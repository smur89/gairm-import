// The structural kinds' constructors, arrays, unions, `not`, objects
// and maps, and the walks the engine runs for them. Leaves live in
// leaf.typ and format.typ, and registry.typ holds a descriptor for
// every kind.

#import "../core/ctx.typ": _at, _absent, _has
#import "../core/error.typ": _error, _type-miss, _type-name-of, _closest-match
#import "constraint.typ": _constraint-errors

/// An array whose every element matches `elem`.
///
/// - elem (dictionary): The schema for each element.
/// -> dictionary
#let array-of(elem) = (kind: "array", elem: elem)

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
// one" (one-of). Match counting lives in _union-walk below, and the
// model is the first matching member's output.
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

// ---- engine behaviour ------------------------------------------------
//
// A structural walk is (schema, value, ctx, recur) -> (errors, value,
// fatal). `recur` is the engine's walk, passed in so kinds/ never
// imports the engine. `value` is the model; `fatal` is none, or the
// first place in walk order where the value leaves no sound model, as
// (expected, got) for coerce's panic text. Every fatal walk also has
// errors, so a walk with no errors has no fatal.
//
// Hot recursive paths use `for` loops, not `.map(x => …)`: each closure
// is a stack frame, and Typst caps the call depth.

#let _array-walk(schema, value, ctx, recur) = {
  if type(value) != array {
    return _type-miss(ctx.path, "array", "an array", value)
  }
  let errors = ()
  let fatal = none
  // Walked items, `none` where an item was absent, so constraints judge
  // what the model holds while uniqueness still cites source indices.
  let items = ()
  for (i, elem) in value.enumerate() {
    let r = recur(schema.elem, elem, _at(ctx, i))
    errors += r.errors
    if fatal == none { fatal = r.fatal }
    items.push(r.value)
  }
  errors += _constraint-errors(schema, "array", items, ctx.path)
  (
    errors: errors,
    // Absent items are dropped: a null in an array of strings would
    // otherwise reach renderers as a stray `none`.
    value: items.filter(v => not _absent(v, ctx)),
    fatal: fatal,
  )
}

// An object that declares no fields and lets anything through is a
// free-form bag (JSON Resume's `custom`): opaque data, so its model is
// the value as given, nulls included.
//
// Keys not in the shape: with `additional: true` they pass through
// unchecked (absent ones dropped), with an `additional` schema each is
// walked against it, and otherwise each is an `unknown-key` error and
// left out of the model. Absent fields are left out too. Only an absent
// value is dropped: an object whose keys were all null stays an empty
// dictionary, since validate counts it as present.
#let _object-walk(schema, value, ctx, recur) = {
  if type(value) != dictionary {
    return _type-miss(ctx.path, "object", "an object", value)
  }
  let additional = schema.at("additional", default: none)
  let errors = ()
  let fatal = none
  let out = (:)
  for (key, sub-value) in value {
    if key in schema.shape or (additional != none and additional != true) {
      let sub-schema = schema.shape.at(key, default: additional)
      let r = recur(sub-schema, sub-value, _at(ctx, key))
      errors += r.errors
      if fatal == none { fatal = r.fatal }
      if not _absent(r.value, ctx) { out.insert(key, r.value) }
    } else if additional == true {
      if not _absent(sub-value, ctx) { out.insert(key, sub-value) }
    } else {
      // Strict: a fuzzy suggestion if the typo is within edit distance
      // 2 of a valid key, otherwise the full key list. An unknown key
      // holding null is still flagged: silently swallowing typos
      // defeats the point of strict validation.
      let suggestion = _closest-match(key, schema.shape.keys(), 2)
      let tail = if suggestion != none {
        "Did you mean " + repr(suggestion) + "?"
      } else {
        "Valid keys: " + schema.shape.keys().join(", ") + "."
      }
      errors += _error(
        ctx.path + (key,),
        "unknown-key",
        "unknown key " + repr(key) + ". " + tail,
        expected: schema.shape.keys(),
        got: key,
      )
    }
  }
  // A required key holding null counts as missing.
  for key in schema.at("required-keys", default: ()) {
    if not _has(value, key, ctx) {
      errors += _error(
        ctx.path + (key,),
        "required",
        "missing required key " + repr(key) + ".",
      )
    }
  }
  // A null trigger does not fire, and a null dependent is missing.
  for (trigger, dependents) in schema.at("dependent-required", default: (:)) {
    if not _has(value, trigger, ctx) { continue }
    for dependent in dependents {
      if not _has(value, dependent, ctx) {
        errors += _error(
          ctx.path,
          "dependent",
          repr(dependent)
            + " is required when "
            + repr(trigger)
            + " is present.",
          expected: dependent,
          got: trigger,
        )
      }
    }
  }
  let model = if _is-free-form(schema) { value } else { out }
  (errors: errors, value: model, fatal: fatal)
}

// anyOf / oneOf. Each member is walked at most once, and the model is
// the first member that walks clean, so nothing is walked a second time
// to build it. any-of stops at that member; one-of walks them all to
// count matches.
//
// With no clean member, one summary error at the union's own path
// rather than every member's failure list: member errors describe
// branches the value never claimed to match, so replaying them all is
// noise. Coerce has no member to build the model from, so it is fatal
// whatever the errors' codes.
#let _union-walk(schema, value, ctx, recur) = {
  let results = ()
  for member in schema.members {
    let r = recur(member, value, ctx)
    if r.errors == () and not schema.exclusive { return r }
    results.push(r)
  }
  let clean = results.filter(r => r.errors == ())
  if clean.len() == 1 { return clean.first() }
  let kinds = schema.members.map(m => m.kind)
  if clean.len() > 1 {
    // The first match still models the value, as for any-of.
    let errors = _error(
      ctx.path,
      "union",
      "expected exactly one alternative to match, but "
        + str(clean.len())
        + " matched.",
      expected: kinds,
    )
    return (errors: errors, value: clean.first().value, fatal: none)
  }
  let fatal = (
    expected: "a value matching one of the union alternatives",
    got: value,
  )
  // A member claims the value when it has no `type` error at the
  // union's own path. When exactly one claims, its own errors say what
  // is wrong; the generic summary would read like a type error for a
  // right-typed value that merely broke a constraint.
  let claimed = results.filter(r => {
    not r.errors.any(e => (
      e.code == "type" and e.path == ctx.path
    ))
  })
  if claimed.len() == 1 {
    return (errors: claimed.first().errors, value: value, fatal: fatal)
  }
  let alternatives = kinds.join(" | ")
  let quantifier = if schema.exclusive { "exactly one" } else { "one" }
  let message = (
    "expected a value matching "
      + quantifier
      + " of: "
      + alternatives
      + "; none matched."
  )
  // No member takes the value's type at all: a type error, so an
  // enclosing union doesn't count this one as claiming it either.
  let errors = if claimed.len() == 0 {
    _error(
      ctx.path,
      "type",
      message,
      expected: alternatives,
      got: _type-name-of(value),
    )
  } else {
    _error(ctx.path, "union", message, expected: kinds)
  }
  (errors: errors, value: value, fatal: fatal)
}

// `not` inverts the member verdict; the member's own errors are
// discarded (they describe why the value is ACCEPTABLE here). There is
// no shape to model toward, so the value passes through as given, like
// an `additional: true` extra.
#let _not-walk(schema, value, ctx, recur) = {
  let r = recur(schema.member, value, ctx)
  let errors = if r.errors == () {
    _error(
      ctx.path,
      "not",
      "expected a value not matching the negated "
        + schema.member.kind
        + " schema.",
    )
  } else { () }
  (errors: errors, value: value, fatal: none)
}
