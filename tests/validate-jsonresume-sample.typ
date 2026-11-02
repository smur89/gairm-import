// Upstream's own sample resume (JSON Resume 1.7.0, `sample.resume.json`
// from the `@jsonresume/schema` npm package, MIT) validates against
// both schemas. Covers the 1.7.0 additions end to end: `objective`,
// `work[].keywords`, string-or-object `location`, `custom`, the new
// certificate / reference / publication fields.

#import "../lib.typ": validate, resume-schema, resume-schema-strict

#let sample = json("fixtures/jsonresume-sample.json")

#assert.eq(validate(sample, schema: resume-schema), ())
#assert.eq(validate(sample, schema: resume-schema-strict), ())

// Strict `meta.lastModified` takes upstream's `YYYY-MM-DDThh:mm:ss`
// (which the sample uses) or a bare date, and nothing else.
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

// 1.7.0 additions strict accepts: the free-form `custom` bag (top level
// and per section), `work[].keywords`, and `location` as a string or the
// structured object.
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

// `work[].keywords` is spec, so the faithful schema takes it too.
#assert.eq(validate(with-keywords, schema: resume-schema), ())

// Unknown keys outside `custom` are still rejected.
#assert.eq(
  validate(
    base + (work: ((name: "Acme", nope: 1),)),
    schema: resume-schema-strict,
  ).map(e => e.path),
  (("work", 0, "nope"),),
)

// The upstream iso8601 pattern now rejects month 13 even in the
// faithful schema.
#assert.ne(
  validate(base + (work: ((startDate: "2024-13"),)), schema: resume-schema),
  (),
)
