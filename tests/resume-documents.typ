// Real resumes end to end, through every entry form and both bundled
// schemas: the minimal and full fixtures, one with nulls throughout,
// and upstream's own sample (JSON Resume 1.7.0, `sample.resume.json`
// from the `@jsonresume/schema` npm package, MIT).

#import "../lib.typ": (
  validate, coerce, parse, resume-schema, resume-schema-strict,
)

// ---- every entry form ------------------------------------------------------

// A dict, a path (read from the caller's file) or bytes give the same
// model, through validate, coerce and parse alike.
#let minimal = "fixtures/resume-minimal.json"
#let model = parse(path(minimal))
#assert.eq(model.basics.name, "Seán Ó Murchú")
#for data in (json(minimal), path(minimal), read(minimal, encoding: none)) {
  assert.eq(validate(data), ())
  assert.eq(coerce(data), model)
  assert.eq(parse(data), model)
}
// Free text is str under the faithful schema, content under strict.
#assert.eq(type(model.basics.summary), str)
#assert.eq(
  type(parse(path(minimal), schema: resume-schema-strict).basics.summary),
  content,
)

// ---- every section ---------------------------------------------------------

#let full = json("fixtures/resume-full.json")
#assert.eq(validate(full), ())
#assert.eq(validate(full, schema: resume-schema-strict), ())
#let faithful = parse(full)
#let strict = parse(full, schema: resume-schema-strict)

#for model in (faithful, strict) {
  assert("name" in model.basics)
  assert("canonical" in model.meta)
  for section in (
    "work",
    "volunteer",
    "education",
    "awards",
    "certificates",
    "publications",
    "skills",
    "languages",
    "interests",
    "references",
    "projects",
  ) {
    assert(model.at(section).len() >= 1, message: section)
  }
  // Tags, identifiers and dates stay strings under both: no override
  // targets them, and strict's date gate checks without converting.
  for value in (
    model.skills.at(0).keywords.at(0),
    model.education.at(0).courses.at(0),
    model.projects.at(0).keywords.at(0),
    model.projects.at(0).roles.at(0),
    model.interests.at(0).keywords.at(0),
    model.basics.email,
    model.work.at(0).url,
    model.work.at(0).startDate,
    model.meta.version,
    model.meta.lastModified,
  ) {
    assert.eq(type(value), str)
  }
}

// Free-text fields: str under the faithful schema, content under strict.
#for get in (
  m => m.basics.summary,
  m => m.work.at(0).summary,
  m => m.work.at(0).highlights.at(0),
  m => m.references.at(0).reference,
  m => m.projects.at(0).description,
  m => m.projects.at(0).highlights.at(0),
  m => m.awards.at(0).summary,
  m => m.publications.at(0).summary,
  m => m.volunteer.at(0).highlights.at(0),
) {
  assert.eq(type(get(faithful)), str)
  assert.eq(type(get(strict)), content)
}

// The fixture's meta.lastModified is a bare date, so this covers the
// date member of strict's datetime-or-date union.
#assert.eq(faithful.meta.lastModified, "2026-06-15")

// ---- nulls throughout ------------------------------------------------------
//
// Most JSON Resume emitters write `"summary": null` for an omitted key.
// Both schemas read null as absent: the document validates and the
// model leaves those keys out.

#let with-nulls = json("fixtures/resume-with-nulls.json")
#assert.eq(validate(with-nulls), ())
#assert.eq(validate(with-nulls, schema: resume-schema-strict), ())
#let faithful = parse(with-nulls)
#let strict = parse(with-nulls, schema: resume-schema-strict)

#for model in (faithful, strict) {
  assert.eq(model.basics, (
    name: "Seán Ó Murchú",
    label: "Senior Software Engineer",
    email: "sean@example.com",
  ))
  // A null work entry is dropped; the survivors keep their order.
  assert.eq(model.work.len(), 2)
  assert.eq(model.work.at(0).name, "Acme Corp")
  assert.eq(model.work.at(0).startDate, "2022-01")
  for key in ("endDate", "summary", "url") {
    assert(key not in model.work.at(0), message: key)
  }
  // Null highlights are dropped.
  assert.eq(model.work.at(0).highlights.len(), 2)
  assert.eq(model.work.at(1).name, "Globex")
  assert.eq(model.work.at(1).position, "Staff Engineer")
  assert.eq(model.work.at(1).startDate, "2018-06")
  assert.eq(model.work.at(1).endDate, "2021-12")
  // Null sections are absent.
  assert.eq(model.keys().sorted(), ("basics", "work"))
}
#assert.eq(faithful.work.at(0).highlights.map(type), (str, str))
#assert.eq(strict.work.at(0).highlights.map(type), (content, content))

// ---- upstream's sample -----------------------------------------------------

#let sample = json("fixtures/jsonresume-sample.json")
#assert.eq(validate(sample, schema: resume-schema), ())
#assert.eq(validate(sample, schema: resume-schema-strict), ())

// Strict meta.lastModified takes upstream's `YYYY-MM-DDThh:mm:ss` (which
// the sample uses) or a bare date, and nothing else.
#let with-modified(value) = (
  basics: (name: "Jane Doe"),
  meta: (lastModified: value),
)
#for ok in ("2026-10-22T14:30:00", "2026-10-22T14:30:00Z", "2026-10-22") {
  assert.eq(validate(with-modified(ok), schema: resume-schema-strict), ())
}
#for bad in ("2026-10-22 14:30", "yesterday") {
  assert.eq(
    validate(with-modified(bad), schema: resume-schema-strict).map(e => e.path),
    (("meta", "lastModified"),),
  )
}

// The 1.7.0 additions strict accepts: the free-form `custom` bag (top
// level and per section), `work[].keywords`, and `location` as a string
// or the structured object. `work[].keywords` is spec, so the faithful
// schema takes it too.
#let base = (basics: (name: "Jane Doe"))
#let with-keywords = base + (work: ((name: "Acme", keywords: ("Scala",)),))
#for doc in (
  base + (custom: (myTool: (theme: "dark"))),
  base + (work: ((name: "Acme", custom: (myTool: 1)),)),
  with-keywords,
  base
    + (
      work: (
        (name: "A", location: "Dublin"),
        (name: "B", location: (city: "Dublin", countryCode: "IE")),
      ),
    ),
) {
  assert.eq(validate(doc, schema: resume-schema-strict), ())
}
#assert.eq(validate(with-keywords, schema: resume-schema), ())

// Unknown keys outside `custom` are still rejected.
#assert.eq(
  validate(
    base + (work: ((name: "Acme", nope: 1),)),
    schema: resume-schema-strict,
  ).map(e => e.path),
  (("work", 0, "nope"),),
)

// The upstream iso8601 pattern rejects month 13 even in the faithful
// schema.
#assert.ne(
  validate(base + (work: ((startDate: "2024-13"),)), schema: resume-schema),
  (),
)
