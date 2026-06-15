// JSON Schema → Typst-schema translator. Mechanical mapping for the
// draft-7 subset the canonical JSON Resume document actually uses;
// unsupported keywords panic with a path-qualified message rather
// than silently dropping shape.
//
// Format-aware string kinds (date-string / uri-string / email-string)
// land in #10 (feat/format-validation). Until they're on main this
// translator degrades all `format`s to `str-type` with a TODO note;
// a one-line follow-up swap will wire them up.

#import "schema.typ": str-type, content-type, number-type, array-of, object

// Resolve an internal $ref like "#/definitions/iso8601" against the
// document root. External $refs (URLs, other documents) panic — we
// do not fetch.
#let _resolve-ref(ref, root) = {
  if not ref.starts-with("#/") {
    panic(
      "json-resume: schema-from-json-schema only supports internal $ref " +
        "(starting with \"#/\"), got: " + repr(ref) + ".",
    )
  }
  let parts = ref.slice(2).split("/")
  parts.fold(root, (acc, key) => {
    if type(acc) != dictionary or key not in acc {
      panic(
        "json-resume: schema-from-json-schema — $ref " + repr(ref) +
          " could not be resolved (segment " + repr(key) + " missing).",
      )
    }
    acc.at(key)
  })
}

// Composition / advanced keywords that aren't in the v0.2 scope.
// Listed explicitly so a schema using one fails loudly instead of
// silently dropping the constraint.
#let _unsupported-keywords = (
  "allOf", "anyOf", "oneOf", "not",
  "enum", "const",
  "if", "then", "else",
  "dependencies", "dependentRequired", "dependentSchemas",
)

#let _from-json-schema(js, root) = {
  if "$ref" in js {
    return _from-json-schema(_resolve-ref(js.at("$ref"), root), root)
  }
  for keyword in _unsupported-keywords {
    if keyword in js {
      panic(
        "json-resume: schema-from-json-schema — unsupported JSON Schema " +
          "keyword: " + repr(keyword) + ". Composition keywords (allOf/anyOf/" +
          "oneOf), enum, and conditional schemas are out of scope.",
      )
    }
  }
  let t = js.at("type", default: none)
  if t == "string" {
    // TODO(#10): once feat/format-validation lands, dispatch on format
    // to date-string / uri-string / email-string. For now everything
    // is str-type — strictly looser than the upstream spec.
    let fmt = js.at("format", default: none)
    if fmt != none and fmt not in ("uri", "email", "date", "date-time") {
      panic(
        "json-resume: schema-from-json-schema — unsupported string format: " +
          repr(fmt) + ".",
      )
    }
    return str-type
  }
  if t == "number" or t == "integer" { return number-type }
  if t == "array" {
    let items = js.at("items", default: none)
    if items == none {
      panic("json-resume: schema-from-json-schema — array schema missing \"items\".")
    }
    return array-of(_from-json-schema(items, root))
  }
  if t == "object" {
    let props = js.at("properties", default: (:))
    let required = js.at("required", default: ())
    return object(
      props.pairs().map(((k, v)) => (k, _from-json-schema(v, root))).to-dict(),
      required-keys: required,
    )
  }
  if t in ("boolean", "null") {
    panic(
      "json-resume: schema-from-json-schema — unsupported JSON Schema type: " +
        repr(t) + ".",
    )
  }
  panic(
    "json-resume: schema-from-json-schema — unrecognised JSON Schema " +
      "fragment (no \"type\" or \"$ref\"); keys: " + repr(js.keys()) + ".",
  )
}

#let schema-from-json-schema(js) = _from-json-schema(js, js)
