// Mirrors README.md, "Bring your own schema": both examples, which
// must produce the same result. book.json and book-schema.json (this
// directory) are fictional fixtures; the asserts are ours.

// Translate an existing .json schema.
#let from-json-schema = {
  import "@preview/gairm-import:0.0.0": parse, schema-from-json-schema

  let book-schema = schema-from-json-schema(json("book-schema.json"))
  let book = parse(path("book.json"), schema: book-schema)
  book
}

// Or build the schema directly in Typst.
#let from-combinators = {
  import "@preview/gairm-import:0.0.0": (
    parse, object, array-of, str-type, number-type,
  )

  let book-schema = object((
    title: str-type,
    author: str-type,
    year: number-type,
    tags: array-of(str-type),
  ))

  let book = parse(path("book.json"), schema: book-schema)
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
