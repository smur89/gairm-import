// Mirrors REFERENCE.md, "Introspection": the output its blocks and
// comments show. The calls match REFERENCE.md; the asserts are ours.
#import "@preview/gairm-import:0.0.0": *

// The `member` schema from "Constructors", drawn in full.
#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
    phone: string(),
  ),
  required-keys: ("name", "email"),
  dependent-required: (phone: ("email",)),
)
#assert.eq(
  describe-schema(member),
  "age     integer (minimum 0)
code    string + pattern
email*  string (email)
name*   string (min-length 1, max-length 80)
phone   string
rating  number (minimum 0, maximum 5, multiple-of 0.5)
tags[]  string (min-items 1, unique-items)
phone → email",
)

// The resume-schema-strict excerpt elides rows, so pin the rows it
// shows, each with the following line where it shows one.
#let described = describe-schema(resume-schema-strict)
#for row in (
  "\nbasics:\n",
  "\n  email     string (email)\n",
  "\n  name      string\n",
  "\n  summary   content\n  url       string (uri)\n",
  "\nmeta:
  canonical     string (uri)
  lastModified  any of:
    [0]  string (date-time)
    [1]  string (date)
  version       string\n",
  "\nwork[]:\n",
  "\n  highlights[]  content
  keywords[]    string
  location      one of:
    [0]  string
    [1]:
      address      string\n",
) {
  assert(described.contains(row), message: row)
}

// The notation for nullable, not and `*` keys.
#assert.eq(describe-schema(object((a: nullable(string())))), "a  string?")
#assert.eq(describe-schema(object((a: not-of(null-type)))), "a:\n  not  null")
#assert.eq(describe-schema(map(number())), "*  number")
#assert.eq(
  describe-schema(if-of(
    string(min-length: 5),
    then: string(pattern: "^x"),
    otherwise: number(),
  )),
  "if    string (min-length 5)\nthen  string + pattern\nelse  number",
)

#let dates = paths-of-kind(resume-schema-strict, string(format: "date"))
#assert.eq(dates.first(), ("awards", "items", "date"))
#assert(("meta", "lastModified", 1) in dates)
#assert.eq(paths-of-kind(member, number()), (("rating",),))
#assert.eq(paths-of-kind(member, number(minimum: 0)), (("rating",),))
#assert.eq(paths-of-kind(member, integer()), (("age",),))
#assert.eq(paths-of-kind(member, pattern-string), (("code",),))
#assert.eq(
  lens-get(resume-schema-strict, ("meta", "lastModified", 0)).kind,
  "string",
)
