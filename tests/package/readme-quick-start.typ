// Mirrors README.md, "Quick start": both examples, which
// must produce the same result. book.json and book-schema.json (this
// directory) are fictional fixtures; the asserts are ours.

// Translate an existing .json schema.
#let from-json-schema = {
  import "@preview/gairm-import:0.0.0": parse, schema-from-json-schema

  let book-schema = schema-from-json-schema(json("book-schema.json"))
  let book = parse(book-schema, path("book.json"))
  book
}

// Or build the schema directly in Typst.
#let from-combinators = {
  import "@preview/gairm-import:0.0.0": parse, object, array-of, string, number

  let book-schema = object(
    (
      title: string(),
      author: string(),
      year: number(),
      tags: array-of(string()),
    ),
    required-keys: ("title", "author", "year", "tags"),
  )

  let book = parse(book-schema, path("book.json"))
  // The README renders it; this only checks the markup compiles.
  let _ = [= #book.title
    #book.author, #book.year: #book.tags.join(", ")]
  book
}

#let expected = (
  title: "The Pocket Atlas of Imaginary Places",
  author: "Aoife Brennan",
  year: 1998,
  tags: ("atlas", "fiction"),
)
#assert.eq(from-json-schema, expected)
#assert.eq(from-combinators, expected)

// "API at a glance": `parse.with(schema)` is a parser for one schema.
#{
  import "@preview/gairm-import:0.0.0": parse, schema-from-json-schema

  let parse-book = parse.with(schema-from-json-schema(json("book-schema.json")))
  assert.eq(parse-book(path("book.json")), expected)
}
