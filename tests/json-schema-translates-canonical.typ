// Integration: the canonical JSON Resume schema.json (v1.0.0)
// translates cleanly and the resulting Typst schema validates a real
// resume document. Proves the translator handles every keyword the
// canonical doc actually uses, not just synthetic fragments.

#import "../lib.typ": schema-from-json-schema, validate, str-type

#let canonical-js = json("../internal/assets/jsonresume-schema.json")
#let canonical = schema-from-json-schema(canonical-js)

// path() route: same translation as the dict form above.
#let canonical-from-path = schema-from-json-schema(
  path("../internal/assets/jsonresume-schema.json"),
)
#assert.eq(
  canonical-from-path.shape.keys().sorted(),
  canonical.shape.keys().sorted(),
)
#assert.eq(
  canonical-from-path.shape.work.elem.shape.startDate.kind,
  "pattern-string",
)

#let expected-keys = (
  "$schema",
  "awards",
  "basics",
  "certificates",
  "education",
  "interests",
  "languages",
  "meta",
  "projects",
  "publications",
  "references",
  "skills",
  "volunteer",
  "work",
).sorted()
#assert.eq(canonical.kind, "object")
#assert.eq(canonical.shape.keys().sorted(), expected-keys)

// Every section is either an object (basics, meta) or array-of-object.
#for (key, sub) in canonical.shape.pairs() {
  if key == "$schema" { continue }
  let ok = (
    sub.kind == "object" or (sub.kind == "array" and sub.elem.kind == "object")
  )
  assert(
    ok,
    message: "canonical."
      + key
      + " not object or array-of-object; kind="
      + sub.kind,
  )
}

// $ref to #/definitions/iso8601 resolves through to a pattern-string
// (the iso8601 definition is a string with a `pattern`) — proves the
// ref-resolver walked the canonical document AND the translator
// honoured the pattern on the resolved leaf. `meta.lastModified` has
// no pattern in upstream, so it stays as plain `str`.
#assert.eq(canonical.shape.work.elem.shape.startDate.kind, "pattern-string")
#assert.eq(canonical.shape.meta.shape.lastModified, str-type)

// End-to-end: the existing full-section fixture validates cleanly
// against the derived schema. Hand-written `resume-schema` already
// accepts this fixture; the derived schema must too, or we've lost
// shape in translation.
#let raw = json("fixtures/resume-full.json")
#assert.eq(validate(raw, schema: canonical), ())
#assert.eq(validate(raw, schema: canonical-from-path), ())
