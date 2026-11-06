// Schema introspection — `describe-schema` pretty-printer,
// `paths-of-kind` leaf enumeration, `kind-at` lens-shortcut.

#import "../lib.typ": (
  describe-schema, paths-of-kind, kind-at, resume-schema, resume-schema-strict,
  object, array-of, str-type, content-type, number-type, date-string,
  uri-string, email-string, enum-of, pattern-string, any-of, const-of, one-of,
  not-of,
)

// --- describe-schema -------------------------------------------------

// Nested objects, leaf alignment, array-of-object header, array-of-leaf
// inline. Alphabetical key ordering pinned via the expected blob.
#let toy = object((
  basics: object((
    name: str-type,
    summary: content-type,
    email: email-string,
    url: uri-string,
  )),
  work: array-of(object((
    name: str-type,
    startDate: date-string,
    highlights: array-of(str-type),
  ))),
))

#let expected = "basics:
  email    email-string
  name     str
  summary  content
  url      uri-string
work[]:
  highlights[]  str
  name          str
  startDate     date-string"

#assert.eq(describe-schema(toy), expected)

// Empty schema — no children, no panic.
#assert.eq(describe-schema(object((:))), "")

// Single leaf at the root (degenerate but supported).
#assert.eq(describe-schema(str-type), "str")

// Enum leaf carries its values inline so callers see the choices.
#let with-enum = object((
  role: enum-of(("ic", "manager")),
))
#assert.eq(describe-schema(with-enum), "role  enum (\"ic\", \"manager\")")

// Array of leaf at the root.
#assert.eq(describe-schema(array-of(number-type)), "[] number")

// Array of object at the root.
#assert.eq(
  describe-schema(array-of(object((name: str-type)))),
  "[]:\n  name  str",
)

// Real schema sanity — must produce a non-empty multi-line string
// and mention top-level sections.
#let canonical = describe-schema(resume-schema)
#assert(canonical.len() > 0)
#assert("basics:" in canonical)
#assert("work[]:" in canonical)
#assert("meta:" in canonical)

// --- paths-of-kind ---------------------------------------------------

// Spec acceptance: strict schema content leaves match _content-paths
// (14 entries). Alphabetical ordering means we can pin the exact list.
#let content-paths = paths-of-kind(resume-schema-strict, "content")
#assert.eq(content-paths.len(), 14)
#assert.eq(content-paths, (
  ("awards", "items", "summary"),
  ("basics", "summary"),
  ("certificates", "items", "summary"),
  ("education", "items", "summary"),
  ("objective",),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
  ("projects", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("volunteer", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("work", "items", "summary"),
))

// `items` segments are lens-compatible — feed one back in.
#import "../lib.typ": lens, lens-get
#assert.eq(
  lens-get(lens(content-paths.at(0)), resume-schema-strict),
  content-type,
)

// Format kinds carry through to the strict schema from the faithful
// base (translator-emitted `format: "uri"` / `format: "email"`).
// Full URI path list pinned so a translator regression surfaces here.
#assert.eq(paths-of-kind(resume-schema-strict, "uri-string"), (
  ("$schema",),
  ("basics", "profiles", "items", "url"),
  ("basics", "url"),
  ("certificates", "items", "url"),
  ("education", "items", "url"),
  ("meta", "canonical"),
  ("projects", "items", "url"),
  ("publications", "items", "url"),
  ("volunteer", "items", "url"),
  ("work", "items", "url"),
))

#assert.eq(
  paths-of-kind(resume-schema-strict, "email-string"),
  (("basics", "email"),),
)

// Date kind: only the strict overlay lifts the iso8601 $ref fields.
// Every upstream date is an iso8601 $ref now, so the faithful base
// has none.
#let date-paths-strict = paths-of-kind(resume-schema-strict, "date-string")
// The 13 _iso8601-date-paths, and meta.lastModified's date member.
#assert.eq(date-paths-strict.len(), 14)
#assert(("meta", "lastModified", 1) in date-paths-strict)
#assert(("work", "items", "startDate") in date-paths-strict)
#assert(("certificates", "items", "date") in date-paths-strict)
#assert.eq(paths-of-kind(resume-schema, "date-string"), ())

// iso8601 $ref fields land as pattern-string in the faithful base
// (translator picks up upstream's `definitions/iso8601` pattern). The
// strict overlay rewrites them to date-string, so they vanish here.
#let iso-paths-faithful = paths-of-kind(resume-schema, "pattern-string")
#assert.eq(iso-paths-faithful.len(), 13)
#assert(("work", "items", "startDate") in iso-paths-faithful)
#assert(("publications", "items", "releaseDate") in iso-paths-faithful)
#assert.eq(paths-of-kind(resume-schema-strict, "pattern-string"), ())

// Empty schema yields an empty result.
#assert.eq(paths-of-kind(object((:)), "str"), ())

// Toy schema — confirm path tuples for a hand-built nested case.
#assert.eq(
  paths-of-kind(toy, "uri-string"),
  (("basics", "url"),),
)
#assert.eq(
  paths-of-kind(toy, "str"),
  (
    ("basics", "name"),
    ("work", "items", "highlights", "items"),
    ("work", "items", "name"),
  ),
)
#assert.eq(
  paths-of-kind(toy, "date-string"),
  (("work", "items", "startDate"),),
)

// --- describe-schema: nested array-of-array -------------------------

// `array-of-array` (e.g. a 2D string matrix) was previously rendered
// inline as `key[]  array`, hiding the inner element kind. Now treated
// as structural so the recursive walk shows the deeper level.
#let matrix-schema = object((
  grid: array-of(array-of(str-type)),
))
#assert.eq(
  describe-schema(matrix-schema),
  "grid[]:\n  [] str",
)

// Three levels deep with content-type at the leaf.
#let cube-schema = object((
  cube: array-of(array-of(array-of(content-type))),
))
#assert.eq(
  describe-schema(cube-schema),
  "cube[]:\n  []:\n    [] content",
)

// --- kind-at ---------------------------------------------------------

#assert.eq(kind-at(resume-schema, ("basics", "name")), "str")
#assert.eq(kind-at(resume-schema, ("basics", "email")), "email-string")
#assert.eq(kind-at(resume-schema-strict, ("basics", "summary")), "content")
#assert.eq(kind-at(resume-schema, ("work", "items")), "object")
#assert.eq(kind-at(resume-schema, ("work",)), "array")
// Empty path is the identity — root kind.
#assert.eq(kind-at(resume-schema, ()), "object")

// Kind values (#135): a schema node matches by its kind; a constructor
// stands for the kind it builds; the name string still works
// (deprecated).
#assert.eq(
  paths-of-kind(resume-schema-strict, date-string),
  paths-of-kind(resume-schema-strict, "date-string"),
)
#assert.eq(
  paths-of-kind(resume-schema, pattern-string),
  paths-of-kind(resume-schema, "pattern-string"),
)
#assert.eq(
  paths-of-kind(resume-schema, pattern-string("x")),
  paths-of-kind(resume-schema, "pattern-string"),
)
#assert.eq(
  paths-of-kind(resume-schema, str-type),
  paths-of-kind(resume-schema, "str"),
)
#assert.eq(paths-of-kind(resume-schema, any-of), paths-of-kind(
  resume-schema,
  "union",
))
// Guard against vacuous equalities above: these kinds are present.
#assert(paths-of-kind(resume-schema-strict, date-string).len() > 0)
#assert(paths-of-kind(resume-schema, pattern-string).len() > 0)
#assert(paths-of-kind(resume-schema, str-type).len() > 0)
#assert(paths-of-kind(resume-schema, any-of).len() > 0)

// resume-schema has no enum or not nodes, so cover every constructor
// against a toy schema where the result is non-empty.
#let kinds-toy = object((
  level: enum-of(("a", "b")),
  fixed: const-of("x"),
  either: any-of((str-type, number-type)),
  exactly: one-of((str-type, number-type)),
  other: not-of(str-type),
))
#assert.eq(paths-of-kind(kinds-toy, enum-of), (("fixed",), ("level",)))
#assert.eq(paths-of-kind(kinds-toy, const-of), (("fixed",), ("level",)))
#assert.eq(paths-of-kind(kinds-toy, any-of), (("either",), ("exactly",)))
#assert.eq(paths-of-kind(kinds-toy, one-of), (("either",), ("exactly",)))
#assert.eq(paths-of-kind(kinds-toy, not-of), (("other",),))
#assert.eq(paths-of-kind(kinds-toy, enum-of), paths-of-kind(kinds-toy, "enum"))
#assert.eq(paths-of-kind(kinds-toy, not-of), paths-of-kind(kinds-toy, "not"))
