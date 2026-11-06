// JSON Schema (draft 7 subset) → Typst-schema translator: the entry
// point, `$ref` resolution, one builder per JSON type and the
// dispatcher. Anything not supported panics rather than silently
// dropping the constraint; keyword.typ says which keywords those are.

#import "../core/input.typ": _decode-input
#import "../core/pointer.typ": _invalid-escape-re, pointer-to-path
#import "../core/ctx.typ": _ctx
#import "../engine.typ": _walk
#import "../kinds/leaf.typ": (
  number-type, integer-type, bool-type, null-type, any-type, enum-of,
)
#import "../kinds/structure.typ": array-of, object, any-of, one-of, not-of
#import "../kinds/format.typ": string, _format-for-json-schema
#import "../kinds/constraint.typ": (
  _constraints, _read-constraints, _clash-message,
)
#import "keyword.typ": (
  _bail, _check-keywords, _check-keywords-typed, _constraint-family,
  _has-keyword-for, _membership-structural, _role-of,
)
#import "all-of.typ": _all-of


// RFC 3986 percent-decoding of a `$ref` fragment, as UTF-8; none when
// a `%` is not followed by two hex digits or the bytes are not UTF-8.
#let _hex-digits = "0123456789abcdef"
#let _utf8-length(lead) = if lead < 0x80 { 1 } else if (
  lead >= 0xC2 and lead < 0xE0
) { 2 } else if lead >= 0xE0 and lead < 0xF0 { 3 } else if (
  lead >= 0xF0 and lead < 0xF5
) { 4 }
#let _percent-decode(s) = {
  if "%" not in s { return s }
  let parts = s.split("%")
  let out = array(bytes(parts.first()))
  for part in parts.slice(1) {
    let digits = part
      .codepoints()
      .slice(0, calc.min(2, part.codepoints().len()))
    let values = digits.map(d => _hex-digits.position(lower(d)))
    if values.len() < 2 or none in values { return none }
    out.push(values.at(0) * 16 + values.at(1))
    out += array(bytes(part.slice(2)))
  }
  let i = 0
  while i < out.len() {
    let n = _utf8-length(out.at(i))
    if n == none or i + n > out.len() { return none }
    if out.slice(i + 1, i + n).any(b => b < 0x80 or b >= 0xC0) { return none }
    i += n
  }
  str(bytes(out))
}

// `seen` is the chain of refs traversed so far; a repeat means a
// cycle (e.g. `definitions.alias → alias`) — panic before Typst's
// recursion limit fires deep in the stack.
#let _resolve-ref(ref, root, seen) = {
  if not ref.starts-with("#/") {
    _bail(
      "only internal $ref (starting with \"#/\") is supported, got: "
        + repr(ref)
        + ".",
    )
  }
  if ref in seen {
    _bail(
      "cyclic $ref detected: "
        + seen.map(repr).join(" → ")
        + " → "
        + repr(ref)
        + ".",
    )
  }
  if ref == "#/" {
    _bail("$ref \"#/\" cannot reference the document root.")
  }
  // The fragment is a URI's, so it is percent-decoded into the pointer
  // (RFC 3986) before the pointer is read (RFC 6901): `%25` is `%`.
  let pointer = _percent-decode(ref.slice(1))
  if pointer == none {
    _bail(
      "$ref "
        + repr(ref)
        + " has a malformed percent escape; `%` must start a `%XX` hex escape of UTF-8 bytes (write `%25` for a literal `%`).",
    )
  }
  // Checked here so a bad escape reports under this module's prefix
  // rather than pointer-to-path's.
  if pointer.match(_invalid-escape-re) != none {
    _bail(
      "$ref "
        + repr(ref)
        + " has an invalid escape; RFC 6901 only allows `~0` (tilde) and `~1` (slash).",
    )
  }
  // RFC 6901: `~1` / `~0` unescape, empty segments are the "" key, and
  // a numeric segment indexes an array (e.g. "#/allOf/0") or names a key.
  pointer-to-path(pointer).fold(root, (acc, seg) => {
    let key = if type(acc) == dictionary { str(seg) } else { seg }
    let found = if type(acc) == dictionary { key in acc } else {
      type(acc) == array and type(seg) == int and seg < acc.len()
    }
    if not found {
      _bail(
        "$ref "
          + repr(ref)
          + " could not be resolved (segment "
          + repr(str(seg))
          + " missing).",
      )
    }
    acc.at(key)
  })
}

// `dependentRequired` (2019-09) and draft 7's array-form `dependencies`
// are the same constraint. The schema form of `dependencies` needs
// conditional schemas, like `dependentSchemas`.
#let _dependent-required(js) = {
  let has-dr = "dependentRequired" in js
  let has-dep = "dependencies" in js
  if has-dr and has-dep {
    _bail(
      "\"dependencies\" and \"dependentRequired\" cannot both be set; use one.",
    )
  }
  if not has-dr and not has-dep { return (:) }
  let keyword = if has-dr { "dependentRequired" } else { "dependencies" }
  let map = js.at(keyword)
  if type(map) != dictionary {
    _bail("\"" + keyword + "\" must be an object, got: " + repr(map) + ".")
  }
  // Checked here, though object() checks them too, so a bad value
  // reports under this module's prefix and the JSON keyword's name.
  for (trigger, dependents) in map {
    if type(dependents) == dictionary {
      _bail(
        "unsupported JSON Schema keyword: the schema form of \"dependencies\" (for "
          + repr(trigger)
          + "). Conditional schemas are out of scope.",
      )
    }
    if type(dependents) != array or dependents.any(d => type(d) != str) {
      _bail(
        "\""
          + keyword
          + "\" for "
          + repr(trigger)
          + " must be an array of field names, got: "
          + repr(dependents)
          + ".",
      )
    }
  }
  map
}

#let _require-member-array(js, keyword) = {
  let members = js.at(keyword)
  if type(members) != array or members.len() == 0 {
    _bail(
      repr(keyword)
        + " must be a non-empty array of schemas, got: "
        + repr(members)
        + ".",
    )
  }
  for m in members {
    if type(m) != dictionary {
      _bail(
        repr(keyword)
          + " members must be schema objects, got: "
          + repr(m)
          + ".",
      )
    }
  }
  members
}

// Both keywords apply when both are present (JSON Schema's "all
// keywords apply"): string() gives the format kind the pattern as an
// extra gate, checked after the format regex. The keywords are checked
// here first, so a bad one bails with the translator's own message.
#let _string-base(js) = {
  let fmt = js.at("format", default: none)
  let pat = js.at("pattern", default: none)
  if pat != none and type(pat) != str {
    _bail("\"pattern\" must be a string, got: " + repr(type(pat)) + ".")
  }
  if fmt != none and type(fmt) != str {
    _bail("\"format\" must be a string, got: " + repr(type(fmt)) + ".")
  }
  if fmt != none and fmt not in _format-for-json-schema {
    _bail("unsupported string format: " + repr(fmt) + ".")
  }
  string(
    format: fmt,
    pattern: pat,
    expected: if pat != none { "matching " + repr(pat) },
  )
}

// No `items`: items of any value, as in draft 7.
#let _array-base(js, ctx, recur) = {
  let items = js.at("items", default: (:))
  if type(items) != dictionary {
    _bail(
      "\"items\" must be a schema object, got: " + repr(type(items)) + ".",
    )
  }
  array-of(recur(items, ctx))
}

#let _object-base(js, ctx, recur) = {
  let has-props = "properties" in js
  let has-ap = "additionalProperties" in js
  // Fully open with no constraints inverts the engine's strict intent.
  if not has-props and not has-ap {
    _bail(
      "open object schemas (`type: \"object\"` with no `properties` "
        + "or `additionalProperties`) are out of scope; every field "
        + "must be declared or covered by `additionalProperties`.",
    )
  }
  let props = if has-props { js.at("properties") } else { (:) }
  if type(props) != dictionary {
    _bail("\"properties\" must be an object, got: " + repr(type(props)) + ".")
  }
  let required = js.at("required", default: ())
  if type(required) != array {
    _bail(
      "\"required\" must be an array of field names, got: "
        + repr(type(required))
        + ".",
    )
  }
  // object() reads the names as keys, so a non-string one would fail
  // there with a raw Typst error, or pass and fail at validation.
  if required.any(k => type(k) != str) {
    _bail(
      "\"required\" must be an array of field names, got: "
        + repr(required)
        + ".",
    )
  }
  let additional = if not has-ap {
    none
  } else {
    let ap = js.at("additionalProperties")
    if ap == false { none } else if ap == true { true } else if (
      type(ap) == dictionary
    ) { recur(ap, ctx) } else {
      _bail(
        "\"additionalProperties\" must be a schema, true, or false, got: "
          + repr(ap)
          + ".",
      )
    }
  }
  object(
    props.pairs().map(((k, v)) => (k, recur(v, ctx))).to-dict(),
    required-keys: required,
    dependent-required: _dependent-required(js),
    additional: additional,
  )
}

// One builder per JSON type, keyed by its `type` name, each reading its
// own keywords from the node and ignoring the others' (JSON Schema
// semantics); the constraint keywords are folded on afterwards.
// `integer` keeps its integral constraint rather than flattening to
// number, which would silently drop it.
#let _builders = (
  string: (js, ctx, recur) => _string-base(js),
  number: (..) => number-type,
  integer: (..) => integer-type,
  array: _array-base,
  object: _object-base,
  boolean: (..) => bool-type,
  "null": (..) => null-type,
)

// Reads the constraint keywords for JSON type `t` onto `node`, bailing
// at translate time on a bad-shape value — better than a kind dict the
// validator can't reason about — and on bounds no value can satisfy
// (min > max, etc.), which would translate cleanly but reject every
// input as a mystery validation failure.
#let _with-constraints(node, js, t) = {
  let family = _constraint-family.at(t, default: none)
  if family == none { return node }
  let read = _read-constraints(node, family, js, row => row.json)
  if read.bad != none {
    let (row, value, must) = read.bad
    _bail(
      repr(row.json) + " must be " + must + ", got: " + repr(value) + ".",
    )
  }
  if read.clash != none {
    _bail(_clash-message(
      read.clash,
      read.node,
      field => _constraints.at(field).json,
    ))
  }
  read.node
}

// The schema for the node as JSON type `t`.
#let _build(js, ctx, t, recur) = _with-constraints(
  _builders.at(t)(js, ctx, recur),
  js,
  t,
)

// Typst type name → JSON Schema `type` name, for the types that map
// one-to-one (numbers are classified separately).
#let _json-type-names = (
  string: "string",
  boolean: "boolean",
  "none": "null",
  array: "array",
  dictionary: "object",
)

// Folds the `type` and constraint keywords beside `enum` / `const` into
// the value set: each value is checked against the schema the node
// builds for its JSON type, and only survivors are kept. Type-specific
// keywords ignore other types (JSON Schema semantics), so a value of a
// type no keyword applies to — a bool, null, object, or a string beside
// only `minimum` — survives.
#let _fold-membership(js, ctx, names, recur) = {
  for keyword in _membership-structural {
    if keyword in js {
      _bail(
        repr(keyword)
          + " cannot be combined with enum/const — it describes object/array structure, which membership does not check.",
      )
    }
  }
  let values = if "enum" in js { js.at("enum") } else { (js.at("const"),) }
  if type(values) != array {
    _bail(
      "\"enum\" must be an array of values, got: " + repr(type(values)) + ".",
    )
  }
  let by-type = ("string", "number", "array")
    .map(t => (t, _build(js, ctx, t, recur)))
    .to-dict()
  let survivors = values.filter(v => {
    let kind = if type(v) in (int, float) { "number" } else {
      _json-type-names.at(str(type(v)), default: "other")
    }
    // `type` keeps a value whose JSON type it names; `integer` is a
    // number with no fractional part (`1.0` passes, per draft 7).
    let allowed = (
      names == none
        or (
          kind in names
            or (
              kind == "number" and "integer" in names and calc.fract(v) == 0
            )
        )
    )
    (
      allowed
        and (
          kind not in by-type
            or _walk(by-type.at(kind), v, _ctx()).errors.len() == 0
        )
    )
  })
  // `enum: []` was always accepted; only report values that constraints
  // eliminated.
  if values.len() > 0 and survivors.len() == 0 {
    _bail(
      "no enum/const value satisfies the accompanying type/constraints, so the schema is unsatisfiable.",
    )
  }
  survivors
}

// The node's `type` names, checked, or none when it has none. Checked
// before the enum / const fold, which would otherwise report a typo
// like `type: "strng"` as "no value satisfies ...".
#let _type-names-of(js) = {
  let t = js.at("type", default: none)
  if t == none { return none }
  if type(t) == array and (t.len() == 0 or t.any(x => type(x) != str)) {
    _bail(
      "\"type\" array must be a non-empty array of type names, got: "
        + repr(t)
        + ".",
    )
  }
  let names = if type(t) == array { t } else { (t,) }
  for m in names {
    if m not in _builders.keys() {
      _bail(
        "unknown `type` name "
          + repr(m)
          + if type(t) == array { " in " + repr(t) }
          + "; expected one of: "
          + _builders.keys().join(", ")
          + ".",
      )
    }
  }
  names
}

// An untyped node is a union of one member per JSON type (`integer` is
// covered by number), each built as a `type` array's member is, so a
// keyword reaches only its own type. Null comes last, as in a `type`
// array.
#let _untyped-types = ("boolean", "object", "array", "number", "string", "null")

// The composition keywords (#108), each with its member schemas.
#let _applicators = (
  allOf: (js, ctx, recur) => _all-of(
    _require-member-array(js, "allOf"),
    ctx,
    recur,
    ref => _resolve-ref(ref, ctx.root, ()),
  ),
  anyOf: (js, ctx, recur) => any-of(
    _require-member-array(js, "anyOf").map(m => recur(m, ctx)),
  ),
  oneOf: (js, ctx, recur) => one-of(
    _require-member-array(js, "oneOf").map(m => recur(m, ctx)),
  ),
  "not": (js, ctx, recur) => {
    let member = js.at("not")
    if type(member) != dictionary {
      _bail("\"not\" must be a schema object, got: " + repr(member) + ".")
    }
    not-of(recur(member, ctx))
  },
)

// `ctx` is the document `root` and `seen`, the chain of `$ref`s that
// led here.
#let _translate(js, ctx) = {
  // A `properties` value or `$ref` target reaches here unchecked; a
  // boolean would otherwise fail with a raw Typst error on `in` below.
  if type(js) != dictionary {
    _bail(
      "a subschema must be a schema object, got: "
        + repr(js)
        + ". Boolean schemas (true / false) are out of scope.",
    )
  }
  _check-keywords(js)
  if "$ref" in js {
    let ref = js.at("$ref")
    if type(ref) != str {
      _bail("\"$ref\" must be a string, got: " + repr(type(ref)) + ".")
    }
    return _translate(
      _resolve-ref(ref, ctx.root, ctx.seen),
      (..ctx, seen: ctx.seen + (ref,)),
    )
  }
  let applicator = js.keys().find(k => _role-of(k) == "applicator")
  if applicator != none {
    return _applicators.at(applicator)(js, ctx, _translate)
  }
  let names = _type-names-of(js)
  if names != none { _check-keywords-typed(js, names) }
  if "enum" in js or "const" in js {
    return enum-of(_fold-membership(js, ctx, names, _translate))
  }
  // Each member is built from the whole node, and any-of, not one-of:
  // `["number", "integer"]` overlaps and must still accept 1. "null"
  // keeps the source's nullability: [X, "null"] is nullable(X). By
  // default that judges every value as X does (a null is absent before
  // the union sees it); with strict-null it accepts null.
  let types = if names != none {
    let non-null = names.filter(x => x != "null").dedup()
    non-null + if "null" in names { ("null",) } else { () }
  } else if _untyped-types.any(t => _has-keyword-for(js, t)) {
    _untyped-types
  } else {
    // No type-specific keyword: any value.
    return any-type
  }
  // Untyped, an object with no `properties` or `additionalProperties`
  // is open, where `type: "object"` bails.
  let open = (
    names == none
      and "properties" not in js
      and "additionalProperties" not in js
  )
  let js = if open { (..js, additionalProperties: true) } else { js }
  let members = types.map(t => _build(js, ctx, t, _translate))
  if members.len() == 1 { members.first() } else { any-of(members) }
}

/// Translates a JSON Schema document (a draft 7 subset) into a schema
/// for `parse`, `validate` and `coerce`. Panics on anything it does not
/// support, rather than dropping the constraint.
///
/// - js (dictionary, path, bytes): The JSON Schema, or where to read it.
///   A `path` resolves from your file.
/// -> dictionary
#let schema-from-json-schema(js) = {
  let parsed = _decode-input("schema-from-json-schema", js)
  // Non-dictionaries are rejected at the boundary so the diagnostic
  // carries the schema-from-json-schema prefix.
  if type(parsed) != dictionary {
    _bail(
      "expected a parsed JSON Schema dict, path(...), or bytes, got: "
        + repr(type(parsed))
        + ".",
    )
  }
  _translate(parsed, (root: parsed, seen: ()))
}
