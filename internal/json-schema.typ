// JSON Schema (draft 7 subset) → Typst-schema translator. Anything
// not supported panics rather than silently dropping the constraint.

#import "core/input.typ": _decode-input
#import "core/pointer.typ": _invalid-escape-re, pointer-to-path
#import "engine.typ": _validate
#import "core/ctx.typ": _ctx
#import "kinds/leaf.typ": (
  str-type, number-type, integer-type, bool-type, null-type, pattern-string,
  enum-of,
)
#import "kinds/structure.typ": (
  array-of, object, any-of, one-of, not-of, nullable,
)
#import "kinds/format.typ": _format-for-json-schema
#import "kinds/constraint.typ": (
  _constraint-rows, _constraints, _value-problem, _bounds-conflict,
)

// One panic prefix so every diagnostic from this module is grep-able
// by "schema-from-json-schema —".
#let _bail(msg) = panic("gairm-import: schema-from-json-schema — " + msg)

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
  // Checked here so a bad escape reports under this module's prefix
  // rather than pointer-to-path's.
  if ref.match(_invalid-escape-re) != none {
    _bail(
      "$ref "
        + repr(ref)
        + " has an invalid escape; RFC 6901 only allows `~0` (tilde) and `~1` (slash).",
    )
  }
  // RFC 6901: `~1` / `~0` unescape, empty segments are the "" key, and
  // a numeric segment indexes an array (e.g. "#/allOf/0") or names a key.
  pointer-to-path(ref.slice(1)).fold(root, (acc, seg) => {
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

#let _unsupported-keywords = (
  "if",
  "then",
  "else",
  "dependentSchemas",
)

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
  // Value shapes are checked by `object()`; only the schema form is
  // invisible to it.
  for (trigger, dependents) in map {
    if type(dependents) == dictionary {
      _bail(
        "unsupported JSON Schema keyword: the schema form of \"dependencies\" (for "
          + repr(trigger)
          + "). Conditional schemas are out of scope.",
      )
    }
  }
  map
}

// Composition keywords (#108). Each must stand alone on its node
// (annotation-only siblings excepted; `$ref` is held to the same rule)
// — a sibling `type` / `properties` / constraint would be silently
// ignored otherwise, and this module's contract is to bail rather than
// drop.
#let _composition-keywords = ("allOf", "anyOf", "oneOf", "not")

// Annotation-only keywords tolerated beside a composition keyword or
// `$ref` — they carry no validation semantics the engine could drop.
#let _annotation-keywords = (
  "$schema",
  "$id",
  "$comment",
  "title",
  "description",
  "default",
  "examples",
  "readOnly",
  "writeOnly",
  "deprecated",
  "definitions",
  "$defs",
)

// Keywords each JSON type supports. A node may carry another type's
// keywords — draft 7 ignores them, and each `type`-array member is
// translated from the whole node — so the allow-list is their union.
#let _family-keywords(family) = (
  _constraint-rows.filter(row => row.family == family).map(row => row.json)
)
#let _type-keywords = (
  string: ("format", "pattern") + _family-keywords("string"),
  number: _family-keywords("number"),
  array: ("items",) + _family-keywords("array"),
  object: (
    "properties",
    "required",
    "additionalProperties",
    "dependentRequired",
    "dependencies",
  ),
)

// Anything else (`minProperties`, `patternProperties`, `contains`, a
// typo like `minLenght`, ...) bails: draft 7 would ignore an unknown
// key, and an unsupported one would lose its constraint.
#let _known-keywords = (
  ("type", "enum", "const", "$ref")
    + _composition-keywords
    + _annotation-keywords
    + _type-keywords.values().join()
)

#let _require-lone-composition(js, keyword) = {
  let extras = js
    .keys()
    .filter(k => k != keyword and k not in _annotation-keywords)
  if extras.len() > 0 {
    _bail(
      "sibling keywords beside "
        + repr(keyword)
        + " are not supported: "
        + extras.map(repr).join(", ")
        + if keyword == "$ref" {
          ". Draft 7 ignores them; move them into the referenced definition."
        } else { ". Move them into the composition members." },
    )
  }
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

// Whether a raw allOf member declares `additionalProperties` false or a
// schema, through `$ref` and nested allOf. Read from the JSON because
// the translated kind can't tell an explicit `false` from an undeclared
// one (both `none`), and draft 7 reads undeclared as open. Runs after
// the member translated, so refs are known to resolve without cycles.
#let _restricts-extras(js, root) = {
  if "$ref" in js {
    return _restricts-extras(_resolve-ref(js.at("$ref"), root, ()), root)
  }
  if "allOf" in js {
    return js.at("allOf").any(m => _restricts-extras(m, root))
  }
  js.at("additionalProperties", default: true) != true
}

// allOf: the object-merge subset — every member must translate to an
// object schema; shapes union (a duplicate key must carry an EQUAL
// sub-schema), required-keys and dependent-required union,
// additionalProperties must agree across all members (undeclared counts
// as closed), and members that restrict extras (`restricts`, see
// _restricts-extras) need identical property sets. Non-object
// composition (e.g. string + extra constraints) stays out of scope;
// deep-merging conflicting sub-schemas is a rabbit hole the engine's
// flat kinds can't express.
#let _merge-all-of(members, restricts) = {
  for m in members {
    if m.kind != "object" {
      _bail(
        "allOf members must all be object schemas; got kind "
          + repr(m.kind)
          + ". Non-object composition is out of scope.",
      )
    }
  }
  let shape = (:)
  let required = ()
  let dependent = (:)
  let additional = none
  for m in members {
    for (key, sub) in m.shape {
      if key in shape and shape.at(key) != sub {
        _bail(
          "allOf members declare conflicting schemas for key "
            + repr(key)
            + ".",
        )
      }
      shape.insert(key, sub)
    }
    required += m
      .at("required-keys", default: ())
      .filter(k => k not in required)
    // Same-trigger dependency lists union, like required-keys.
    for (trigger, dependents) in m.at("dependent-required", default: (:)) {
      let merged = dependent.at(trigger, default: ())
      dependent.insert(
        trigger,
        merged + dependents.filter(d => d not in merged),
      )
    }
  }
  // additionalProperties must agree across ALL members, with an
  // undeclared member counting as closed (`none`) — silently taking
  // the open (or typed) member's value would accept keys another
  // member rejects.
  let additionals = members.map(m => m.at("additional", default: none))
  for a in additionals {
    if a != additionals.at(0) {
      _bail(
        "allOf members declare conflicting additionalProperties (open, closed, and typed members must all agree).",
      )
    }
  }
  // Draft 7 applies each member's additionalProperties to that member's
  // own properties only: a closed member rejects, and a typed one
  // checks, keys only another member declares, which the union would
  // accept unchecked.
  let keys = members.map(m => m.shape.keys().sorted())
  if restricts.any(r => r) and keys.any(k => k != keys.at(0)) {
    _bail(
      "allOf members with `additionalProperties: false` or a schema must all declare the same properties: draft 7 applies each member's additionalProperties to its own properties only, so a merged schema would accept keys that member rejects. Declare the properties in every member, or drop the restriction.",
    )
  }
  object(
    shape,
    required-keys: required,
    dependent-required: dependent,
    additional: additionals.at(0),
  )
}

// X when `node` is nullable(X), else none.
#let _nullable-of(node) = {
  let members = node.at("members", default: ())
  if members != () and node == nullable(members.first()) {
    members.first()
  }
}

// A member translated from `type: ["object", "null"]` is nullable(object):
// merge its object. A null meets allOf only when every member takes it,
// so the merge is nullable only then.
#let _merge-all-of-nullable(members, restricts) = {
  let inner = members.map(m => _nullable-of(m))
  let merged = _merge-all-of(
    members.zip(inner).map(((m, x)) => if x == none { m } else { x }),
    restricts,
  )
  if inner.all(x => x != none) { nullable(merged) } else { merged }
}

// Reads the constraint keywords of `family` onto `node`, bailing at
// translate time on a bad-shape value — better than a kind dict the
// validator can't reason about — and on bounds no value can satisfy
// (min > max, etc.), which would translate cleanly but reject every
// input as a mystery validation failure.
#let _with-constraints(node, js, family) = {
  let result = node
  for row in _constraint-rows {
    if row.family != family or row.json not in js { continue }
    let v = js.at(row.json)
    let must = _value-problem(row, v)
    if must != none {
      _bail(repr(row.json) + " must be " + must + ", got: " + repr(v) + ".")
    }
    // `uniqueItems: false` is the default: leave it off the node.
    if v != false { result.insert(row.field, v) }
  }
  let clash = _bounds-conflict(result)
  if clash != none {
    let (lower, upper) = (clash.lower, clash.upper).map(field => (
      _constraints.at(field).json + " (" + repr(result.at(field)) + ")"
    ))
    _bail(
      if clash.strict {
        lower + " and " + upper + " leave no satisfying value."
      } else { lower + " > " + upper + " is unsatisfiable." },
    )
  }
  result
}

// Both keywords apply when both are present (JSON Schema's "all
// keywords apply"): the format kind carries the pattern as an extra
// gate, checked after the format regex.
#let _string-base(js) = {
  let fmt = js.at("format", default: none)
  let pat = js.at("pattern", default: none)
  if pat != none and type(pat) != str {
    _bail("\"pattern\" must be a string, got: " + repr(type(pat)) + ".")
  }
  let expected = if pat != none { "matching " + repr(pat) }
  if fmt != none {
    if fmt not in _format-for-json-schema {
      _bail("unsupported string format: " + repr(fmt) + ".")
    }
    let base = _format-for-json-schema.at(fmt)
    if pat == none { base } else {
      base + (pattern: regex(pat), expected: expected)
    }
  } else if pat != none {
    pattern-string(pat, expected: expected)
  } else {
    str-type
  }
}

// Typst type name → JSON Schema `type` name, for the types that map
// one-to-one (numbers are classified separately).
#let _json-type-names = (
  string: "string",
  boolean: "boolean",
  "none": "null",
  array: "array",
  dictionary: "object",
)

// Object / array keywords describe structure that an enum / const
// value list cannot be filtered by here; they bail rather than being
// silently dropped.
#let _membership-structural-keywords = (
  "properties",
  "required",
  "additionalProperties",
  "items",
  "dependentRequired",
  "dependencies",
)

// Accepts any value; constraints that never look at array items need an
// element schema all the same.
#let _any-elem = not-of(enum-of(()))

// Folds the constraint keywords beside `enum` / `const` into the value
// set: each value is checked against the schema the translator would
// have emitted for its JSON type without the membership keyword, and
// only survivors are kept. Type-specific keywords ignore other types
// (JSON Schema semantics), so a value of a type no keyword applies to
// — a bool, null, object, or a string beside only `minimum` — survives.
#let _fold-constraints(js, values) = {
  let by-type = (
    string: _with-constraints(_string-base(js), js, "string"),
    number: _with-constraints(number-type, js, "number"),
    array: _with-constraints(array-of(_any-elem), js, "array"),
  )
  let types = js.at("type", default: none)
  if types != none and type(types) != array { types = (types,) }
  let survivors = values.filter(v => {
    let kind = if type(v) in (int, float) { "number" } else {
      _json-type-names.at(str(type(v)), default: "other")
    }
    // `type` keeps a value whose JSON type it names; `integer` is a
    // number with no fractional part (`1.0` passes, per draft 7).
    let allowed = (
      types == none
        or (
          kind in types
            or (
              kind == "number" and "integer" in types and calc.fract(v) == 0
            )
        )
    )
    (
      allowed
        and (
          kind not in by-type
            or _validate(by-type.at(kind), v, _ctx()).len() == 0
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

#let _type-names = (
  "string",
  "number",
  "integer",
  "array",
  "object",
  "boolean",
  "null",
)

#let _from-json-schema(js, root, seen) = {
  // A `properties` value or `$ref` target reaches here unchecked; a
  // boolean would otherwise fail with a raw Typst error on `in` below.
  if type(js) != dictionary {
    _bail(
      "a subschema must be a schema object, got: "
        + repr(js)
        + ". Boolean schemas (true / false) are out of scope.",
    )
  }
  // Before the $ref early return: resolving the ref first would
  // silently drop any non-annotation sibling of `$ref` (a composition
  // keyword, `minLength`, ...), so bail on those instead.
  for keyword in _composition-keywords + ("$ref",) {
    if keyword in js { _require-lone-composition(js, keyword) }
  }
  if "$ref" in js {
    let ref = js.at("$ref")
    if type(ref) != str {
      _bail("\"$ref\" must be a string, got: " + repr(type(ref)) + ".")
    }
    return _from-json-schema(
      _resolve-ref(ref, root, seen),
      root,
      seen + (ref,),
    )
  }
  for keyword in _unsupported-keywords {
    if keyword in js {
      _bail(
        "unsupported JSON Schema keyword: "
          + repr(keyword)
          + ". Conditional schemas (if/then/else, dependentSchemas, schema-form dependencies) are out of scope.",
      )
    }
  }
  let unknown = js.keys().filter(k => k not in _known-keywords)
  if unknown.len() > 0 {
    _bail(
      "unsupported JSON Schema keyword(s): "
        + unknown.map(repr).join(", ")
        + ". They are outside the supported subset (see the README); translating would silently drop their constraints.",
    )
  }
  // Before the enum / const fold, which would otherwise report a typo
  // like `type: "strng"` as "no value satisfies ...".
  let js-type = js.at("type", default: none)
  if type(js-type) == array {
    if js-type.len() == 0 or js-type.any(x => type(x) != str) {
      _bail(
        "\"type\" array must be a non-empty array of type names, got: "
          + repr(js-type)
          + ".",
      )
    }
  }
  if js-type != none {
    let names = if type(js-type) == array { js-type } else { (js-type,) }
    for m in names {
      if m not in _type-names {
        _bail(
          "unknown `type` name "
            + repr(m)
            + if type(js-type) == array { " in " + repr(js-type) }
            + "; expected one of: "
            + _type-names.join(", ")
            + ".",
        )
      }
    }
  }
  let dependent = _dependent-required(js)
  // Only an object (possibly nullable) can carry it; elsewhere it
  // would be silently dropped.
  let is-object = (
    js-type == "object"
      or (
        type(js-type) == array and "object" in js-type
      )
  )
  if dependent.len() > 0 and not is-object {
    _bail(
      "\"dependencies\" / \"dependentRequired\" are only supported on `type: \"object\"` schemas.",
    )
  }
  if "allOf" in js {
    let raw = _require-member-array(js, "allOf")
    return _merge-all-of-nullable(
      raw.map(m => _from-json-schema(m, root, seen)),
      raw.map(m => _restricts-extras(m, root)),
    )
  }
  if "anyOf" in js {
    return any-of(
      _require-member-array(js, "anyOf").map(m => _from-json-schema(
        m,
        root,
        seen,
      )),
    )
  }
  if "oneOf" in js {
    return one-of(
      _require-member-array(js, "oneOf").map(m => _from-json-schema(
        m,
        root,
        seen,
      )),
    )
  }
  if "not" in js {
    let member = js.at("not")
    if type(member) != dictionary {
      _bail("\"not\" must be a schema object, got: " + repr(member) + ".")
    }
    return not-of(_from-json-schema(member, root, seen))
  }
  // enum / const fold the accompanying `type` and constraint keywords
  // into the value list (see _fold-constraints).
  if "enum" in js or "const" in js {
    for keyword in _membership-structural-keywords {
      if keyword in js {
        _bail(
          repr(keyword)
            + " cannot be combined with enum/const — it describes object/array structure, which membership does not check.",
        )
      }
    }
  }
  if "enum" in js {
    let values = js.at("enum")
    if type(values) != array {
      _bail(
        "\"enum\" must be an array of values, got: " + repr(type(values)) + ".",
      )
    }
    return enum-of(_fold-constraints(js, values))
  }
  if "const" in js {
    return enum-of(_fold-constraints(js, (js.at("const"),)))
  }
  let t = js.at("type", default: none)
  if t == "string" {
    return _with-constraints(_string-base(js), js, "string")
  }
  if t == "number" or t == "integer" {
    // `integer` keeps its integral constraint (kinds/leaf.typ's integer-type)
    // rather than flattening to plain number — silently dropping the
    // constraint would violate this module's contract.
    return _with-constraints(
      if t == "integer" { integer-type } else { number-type },
      js,
      "number",
    )
  }
  if t == "array" {
    let items = js.at("items", default: none)
    if items == none {
      _bail("array schema missing \"items\".")
    }
    if type(items) != dictionary {
      _bail(
        "\"items\" must be a schema object, got: " + repr(type(items)) + ".",
      )
    }
    return _with-constraints(
      array-of(_from-json-schema(items, root, seen)),
      js,
      "array",
    )
  }
  if t == "object" {
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
    let additional = if not has-ap {
      none
    } else {
      let ap = js.at("additionalProperties")
      if ap == false { none } else if ap == true { true } else if (
        type(ap) == dictionary
      ) { _from-json-schema(ap, root, seen) } else {
        _bail(
          "\"additionalProperties\" must be a schema, true, or false, got: "
            + repr(ap)
            + ".",
        )
      }
    }
    return object(
      props
        .pairs()
        .map(((k, v)) => (k, _from-json-schema(v, root, seen)))
        .to-dict(),
      required-keys: required,
      dependent-required: dependent,
      additional: additional,
    )
  }
  if t == "boolean" { return bool-type }
  if t == "null" { return null-type }
  if type(t) == array {
    // "null" keeps the source's nullability: [X, "null"] is nullable(X)
    // and several types plus "null" end in a null-type member. By
    // default that judges every value as X does (a null is absent
    // before the union sees it); with strict-null it accepts null.
    let nullable-type = "null" in t
    let non-null = t.filter(x => x != "null").dedup()
    if non-null.len() == 0 { return null-type }
    // Each member is translated from the whole node with `type` narrowed
    // to that member, so type-specific keywords (minLength, minimum,
    // items, ...) reach only the member they belong to — JSON Schema
    // ignores them for other types. any-of, not one-of: `["number",
    // "integer"]` overlaps and must still accept 1.
    // Dependency keywords belong to the object member only; the others
    // would reject them.
    let members = non-null.map(m => {
      let member = (..js, type: m)
      if m != "object" {
        let _ = member.remove("dependentRequired", default: none)
        let _ = member.remove("dependencies", default: none)
      }
      _from-json-schema(member, root, seen)
    })
    if members.len() == 1 {
      return if nullable-type { nullable(members.at(0)) } else { members.at(0) }
    }
    return any-of(if nullable-type { members + (null-type,) } else { members })
  }
  _bail(
    "unrecognised JSON Schema fragment (no recognised \"type\" or \"$ref\"); keys: "
      + repr(js.keys())
      + ".",
  )
}

// Non-dictionaries are rejected at the boundary so the diagnostic
// carries the schema-from-json-schema prefix instead of failing deep
// inside _from-json-schema.
/// Translates a JSON Schema document (a draft 7 subset) into a schema
/// for `parse`, `validate` and `coerce`. Panics on anything it does not
/// support, rather than dropping the constraint.
///
/// - js (dictionary, path, bytes): The JSON Schema, or where to read it.
///   A `path` resolves from your file.
/// -> dictionary
#let schema-from-json-schema(js) = {
  let parsed = _decode-input("schema-from-json-schema", js)
  if type(parsed) != dictionary {
    _bail(
      "expected a parsed JSON Schema dict, path(...), or bytes, got: "
        + repr(type(parsed))
        + ".",
    )
  }
  _from-json-schema(parsed, parsed, ())
}
