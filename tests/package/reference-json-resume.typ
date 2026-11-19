// Mirrors REFERENCE.md, "A stricter JSON Resume": the recipe, and the
// misspelt-key report it shows. REFERENCE reads the user's own
// `resume.schema.json`; here that is the test fixture's copy.
#import "@preview/gairm-import:0.0.0": (
  parse, validate, format-errors, schema-from-json-schema, schema-put, markup,
)
#import "readme-json-resume.typ": resume-schema, schema-file

// Not for schemas with `not` or `if`: closing an object there loosens them.
#let close(js) = if type(js) == dictionary {
  let js = js.pairs().map(((k, v)) => (k, close(v))).to-dict()
  if (
    "properties" in js and js.at("additionalProperties", default: true) == true
  ) {
    js.additionalProperties = false
  }
  js
} else if type(js) == array { js.map(close) } else { js }

#let strict-json = {
  let js = close(json(schema-file))
  // A full date, or the year and month JSON Resume also allows.
  js.definitions.iso8601 = (
    anyOf: (
      (type: "string", format: "date"),
      (type: "string", pattern: "^[0-9]{4}(-(0[1-9]|1[0-2]))?$"),
    ),
  )
  js
}

#let resume-schema-strict = (
  ("objective",),
  ("basics", "summary"),
  ("work", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("volunteer", "items", "highlights", "items"),
  ("education", "items", "summary"),
  ("awards", "items", "summary"),
  ("certificates", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("projects", "items", "summary"),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
).fold(
  schema-from-json-schema(strict-json),
  (schema, at) => schema-put(schema, at, markup()),
)

#let resume = parse(resume-schema-strict, path("resume.json"))

// The fixture tests run against the same schema.
#{
  import "/tests/fixtures/resume.typ" as fixture
  assert.eq(resume-schema-strict, fixture.resume-schema-strict)
}

// The strict schema reports a misspelt work key with a suggestion; the
// upstream one lets it through.
#{
  let doc = (work: ((name: "Acme", positon: "Engineer"),))
  assert(
    format-errors(validate(resume-schema-strict, doc)).contains(
      "  - work[0].positon: unknown key \"positon\". Did you mean \"position\"?",
    ),
  )
  assert.eq(validate(resume-schema, doc), ())
}
