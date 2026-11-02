// Upstream's own sample resume (JSON Resume 1.7.0, `sample.resume.json`
// from the `@jsonresume/schema` npm package, MIT) validates against
// both schemas. Covers the 1.7.0 additions end to end: `objective`,
// `work[].keywords`, string-or-object `location`, `custom`, the new
// certificate / reference / publication fields.

#import "../lib.typ": validate, resume-schema, resume-schema-strict

#let sample = json("fixtures/jsonresume-sample.json")

#assert.eq(validate(sample, schema: resume-schema), ())

// Strict's one known gap: `meta.lastModified` is lifted to the
// date-only `date-string`, but upstream describes (and the sample
// uses) `YYYY-MM-DDThh:mm:ss`. If strict ever accepts datetimes here,
// this pin fails — drop it then.
#let strict-errors = validate(sample, schema: resume-schema-strict)
#assert.eq(strict-errors.map(e => e.path), (("meta", "lastModified"),))

// The new free-form `custom` bag stays open in strict, while unknown
// keys elsewhere are still rejected.
#let base = (basics: (name: "Jane Doe"))
#assert.eq(
  validate(
    base + (custom: (myTool: (theme: "dark"))),
    schema: resume-schema-strict,
  ),
  (),
)
#assert.eq(
  validate(
    base + (work: ((name: "Acme", custom: (myTool: 1)),)),
    schema: resume-schema-strict,
  ),
  (),
)
#assert.eq(
  validate(
    base + (work: ((name: "Acme", nope: 1),)),
    schema: resume-schema-strict,
  ).map(e => e.path),
  (("work", 0, "nope"),),
)

// `work[].keywords` is spec now, in both schemas.
#let with-keywords = base + (work: ((name: "Acme", keywords: ("Scala",)),))
#assert.eq(validate(with-keywords, schema: resume-schema), ())
#assert.eq(validate(with-keywords, schema: resume-schema-strict), ())

// `location` on work / volunteer / education takes a string or the
// structured object.
#assert.eq(
  validate(
    base
      + (
        work: (
          (name: "A", location: "Dublin"),
          (name: "B", location: (city: "Dublin", countryCode: "IE")),
        ),
      ),
    schema: resume-schema-strict,
  ),
  (),
)

// The upstream iso8601 pattern now rejects month 13 even in the
// faithful schema.
#assert.ne(
  validate(base + (work: ((startDate: "2024-13"),)), schema: resume-schema),
  (),
)
