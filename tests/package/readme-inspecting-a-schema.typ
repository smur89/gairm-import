// Mirrors README.md, "Inspecting a schema": the output its comments
// show. The import and calls match the README; the asserts are ours.
#import "@preview/gairm-import:0.0.0": (
  resume-schema-strict, describe-schema, paths-of-kind, kind-at, date-string,
)

// The README elides rows of each block, so it pins the rows it shows.
#let described = describe-schema(resume-schema-strict)
#for row in (
  "\nbasics:\n",
  "\nmeta:
  canonical     uri-string
  lastModified  any of:
    [0]  datetime-string
    [1]  date-string
  version       string\n",
  "\nwork[]:\n",
  "\n  highlights[]  content
  keywords[]    string
  location      one of:
    [0]  string
    [1]:
      address      string\n",
  "\n  startDate     date-string\n",
) {
  assert(described.contains(row), message: row)
}
// The basics rows, whose column is wider in the full output than the
// README's elided excerpt shows.
#for (label, kind) in (
  ("email", "email-string"),
  ("name", "string"),
  ("summary", "content"),
) {
  assert(
    described.contains(regex("\n  " + label + " +" + kind + "\n")),
    message: label,
  )
}

#let dates = paths-of-kind(resume-schema-strict, date-string)
#assert.eq(dates.first(), ("awards", "items", "date"))
#assert(("meta", "lastModified", 1) in dates)

#assert.eq(kind-at(resume-schema-strict, ("basics", "summary")), "content")
#assert.eq(
  kind-at(resume-schema-strict, ("meta", "lastModified", 0)),
  "datetime-string",
)
