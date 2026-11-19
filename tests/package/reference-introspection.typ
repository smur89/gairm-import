// Mirrors REFERENCE.md, "Introspection": the output its blocks and
// comments show. The calls match REFERENCE.md; the asserts are ours.
#import "@preview/gairm-import:0.0.0": *
#import "reference-schemas.typ": member, team

// The `member` schema from "Constructors", drawn in full.
#assert.eq(
  describe-schema(member),
  "age       integer (minimum 0)
code      string + pattern
email*    string (email)
homepage  string (uri)
joined    string (date)
name*     string (min-length 1, max-length 80)
phone     string
rating    number (minimum 0, maximum 5, multiple-of 0.5)
tags[]    string (min-items 1, unique-items)
phone → email",
)

// The `team` block elides member's middle rows, so pin the rows around
// the elision and the whole drawing on either side of it.
#let described = describe-schema(team)
#assert(
  described.starts-with(
    "contact  one of:
  [0]  string (email)
  [1]:
    phone*  string
lead     string?
members*[]:
  age       integer (minimum 0)
",
  ),
)
#assert(
  described.ends-with(
    "
  tags[]    string (min-items 1, unique-items)
  phone → email
name*    string",
  ),
)

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

#assert.eq(
  find-paths(team, string(format: "email")),
  (("contact", 0), ("members", "items", "email")),
)
#assert.eq(find-paths(member, number()), (("rating",),))
#assert.eq(find-paths(member, number(minimum: 0)), (("rating",),))
#assert.eq(find-paths(member, integer()), (("age",),))
// A pattern's expected text does not decide the match.
#assert.eq(find-paths(member, string(pattern: "^[A-Z]{3}$")), (("code",),))
#assert.eq(lens-get(team, ("contact", 0)).format, "email")
