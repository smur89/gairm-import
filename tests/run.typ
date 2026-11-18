// The run functions' calling convention: the schema, then the data,
// so `.with(schema)` makes a parser for one schema.
#import "../lib.typ": validate, coerce, parse, format-errors, object, string

#let s = object((title: string()))
#let parse-book = parse.with(s)
#assert.eq(parse-book((title: "Atlas")), (title: "Atlas"))
#assert.eq(validate.with(s)((title: 1)).map(e => e.code), ("type",))
#assert.eq(coerce.with(s)((title: "Atlas", x: 1)), (title: "Atlas"))

// format-errors words an empty list as no problems, not as "found 0".
#assert.eq(format-errors(()), "gairm-import: found no problems in the input.")
