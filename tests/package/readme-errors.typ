// Mirrors README.md, "Errors": the combined report for the misspelt
// book, the record its first line comes from, where a missing key's
// error points, and the format-errors example. The report text must
// match the README's block (after "panicked with: ").
#import "@preview/gairm-import:0.0.0": (
  validate, coerce, format-errors, schema-from-json-schema,
)

#let book-schema = schema-from-json-schema(json("book-schema.json"))
#let doc = (
  title: "The Pocket Atlas of Imaginary Places",
  author: 1998,
  yaer: 1998,
  tags: ("atlas", 3),
)

#assert.eq(
  format-errors(validate(book-schema, doc)),
  "gairm-import: found 4 problems in the input:
  - author: expected string, got integer.
  - yaer: unknown key \"yaer\". Did you mean \"year\"?
  - tags[1]: expected string, got integer.
  - year: missing required key \"year\".",
)

#assert.eq(validate(book-schema, doc).first(), (
  path: ("author",),
  code: "type",
  message: "expected string, got integer.",
  expected: "string",
  got: "integer",
))

// A missing key's record points at the key.
#assert.eq(validate(book-schema, doc).last().path, ("year",))

// The format-errors example, on the valid book.json.
#let errors = validate(book-schema, json("book.json"))
#assert.eq(errors, ())
#assert.eq(
  coerce(book-schema, json("book.json")).title,
  "The Pocket Atlas of Imaginary Places",
)

// "whose schemas require all four fields": the Typst schema from Quick
// start reports the same problems as the translated one.
#{
  import "@preview/gairm-import:0.0.0": object, string, number, array-of
  let typst-schema = object(
    (
      title: string(),
      author: string(),
      year: number(),
      tags: array-of(string()),
    ),
    required-keys: ("title", "author", "year", "tags"),
  )
  assert.eq(validate(typst-schema, doc), validate(book-schema, doc))
}

// The format-errors example, verbatim, with the translated schema.
#let doc = json("book.json")
#let errors = validate(book-schema, doc)
#if errors.len() > 0 {
  [Book has #errors.len() issue(s).]
  raw(format-errors(errors))
} else {
  let book = coerce(book-schema, doc)
  // render book …
}
