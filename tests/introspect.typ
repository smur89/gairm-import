// Schema introspection: `describe-schema` draws a schema, `paths-of-kind`
// lists the lens path of every node of a kind. Both reach into union
// and `not` members
// (#164) and conditionals (#109): a union member's segment is its
// index, a `not` member's is "not", and a conditional's are "if",
// "then" and "else".

#import "../lib.typ": (
  describe-schema, paths-of-kind, lens-get, object, array-of, map, content-type,
  bool-type, null-type, enum-of, any-of, const-of, one-of, not-of, if-of,
  nullable, string, number, integer,
)
#import "fixtures/resume.typ": resume-schema, resume-schema-strict

// --- describe-schema -------------------------------------------------

// Nested objects, leaf alignment, array-of-object header, array-of-leaf
// inline. Alphabetical key ordering pinned via the expected blob.
#let toy = object((
  basics: object((
    name: string(),
    summary: content-type,
    email: string(format: "email"),
    url: string(format: "uri"),
  )),
  work: array-of(object((
    name: string(),
    startDate: string(format: "date"),
    highlights: array-of(string()),
  ))),
))

#let expected = "basics:
  email    string (email)
  name     string
  summary  content
  url      string (uri)
work[]:
  highlights[]  string
  name          string
  startDate     string (date)"

#assert.eq(describe-schema(toy), expected)

// Empty schema — no children, no panic.
#assert.eq(describe-schema(object((:))), "")

// Single leaf at the root (degenerate but supported).
#assert.eq(describe-schema(string()), "string")

// Enum leaf carries its values inline so callers see the choices.
#let with-enum = object((
  role: enum-of(("ic", "manager")),
))
#assert.eq(describe-schema(with-enum), "role  enum (\"ic\", \"manager\")")

// Array of leaf at the root.
#assert.eq(describe-schema(array-of(number())), "[] number")

// Array of object at the root.
#assert.eq(
  describe-schema(array-of(object((name: string())))),
  "[]:\n  name  string",
)

// Real schema sanity — must produce a non-empty multi-line string
// and mention top-level sections.
#let canonical = describe-schema(resume-schema)
#assert(canonical.len() > 0)
#assert("basics:" in canonical)
#assert("work[]:" in canonical)
#assert("meta:" in canonical)

// --- paths-of-kind ---------------------------------------------------

// The strict schema's content leaves are the fixture's content-paths
// (14 entries). Alphabetical ordering means we can pin the exact list.
#let content-paths = paths-of-kind(resume-schema-strict, content-type)
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
#assert.eq(lens-get(resume-schema-strict, content-paths.at(0)), content-type)

// Formats carry through to the strict schema from the faithful
// base (translator-emitted `format: "uri"` / `format: "email"`).
// Full URI path list pinned so a translator regression surfaces here.
#assert.eq(paths-of-kind(resume-schema-strict, string(format: "uri")), (
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
  paths-of-kind(resume-schema-strict, string(format: "email")),
  (("basics", "email"),),
)

// Date format: only the strict schema lifts the iso8601 $ref fields.
// Every upstream date is an iso8601 $ref now, so the faithful base
// has none.
#let date-paths-strict = paths-of-kind(
  resume-schema-strict,
  string(format: "date"),
)
// The 13 iso8601 $ref fields, and meta.lastModified's date member.
#assert.eq(date-paths-strict.len(), 14)
#assert(("meta", "lastModified", 1) in date-paths-strict)
#assert(("work", "items", "startDate") in date-paths-strict)
#assert(("certificates", "items", "date") in date-paths-strict)
#assert.eq(paths-of-kind(resume-schema, string(format: "date")), ())

// iso8601 $ref fields land as patterned strings in the faithful base
// (translator picks up upstream's `definitions/iso8601` pattern). The
// strict schema rewrites them to date strings, so they vanish there.
// The query is one of them, so it finds every string with that pattern.
#let iso8601 = lens-get(resume-schema, ("work", "items", "startDate"))
#let iso-paths-faithful = paths-of-kind(resume-schema, iso8601)
#assert.eq(iso-paths-faithful.len(), 13)
#assert(("work", "items", "startDate") in iso-paths-faithful)
#assert(("publications", "items", "releaseDate") in iso-paths-faithful)
#assert.eq(paths-of-kind(resume-schema-strict, iso8601), ())

// Empty schema yields an empty result.
#assert.eq(paths-of-kind(object((:)), string()), ())

// Toy schema — confirm path tuples for a hand-built nested case.
#assert.eq(
  paths-of-kind(toy, string(format: "uri")),
  (("basics", "url"),),
)
#assert.eq(
  paths-of-kind(toy, string()),
  (
    ("basics", "email"),
    ("basics", "name"),
    ("basics", "url"),
    ("work", "items", "highlights", "items"),
    ("work", "items", "name"),
    ("work", "items", "startDate"),
  ),
)
#assert.eq(
  paths-of-kind(toy, string(format: "date")),
  (("work", "items", "startDate"),),
)

// --- describe-schema: nested array-of-array -------------------------

// `array-of-array` (e.g. a 2D string matrix) was previously rendered
// inline as `key[]  array`, hiding the inner element kind. Now treated
// as structural so the recursive walk shows the deeper level.
#let matrix-schema = object((
  grid: array-of(array-of(string())),
))
#assert.eq(
  describe-schema(matrix-schema),
  "grid[]:\n  [] string",
)

// Three levels deep with content-type at the leaf.
#let cube-schema = object((
  cube: array-of(array-of(array-of(content-type))),
))
#assert.eq(
  describe-schema(cube-schema),
  "cube[]:\n  []:\n    [] content",
)

// --- the kind at a location ----------------------------------------

#assert.eq(lens-get(resume-schema, ("basics", "name")).kind, "string")
// A formatted string is a string; its format is a field.
#assert.eq(lens-get(resume-schema, ("basics", "email")).kind, "string")
#assert.eq(lens-get(resume-schema, ("basics", "email")).format, "email")
#assert.eq(
  lens-get(resume-schema-strict, ("basics", "summary")).kind,
  "content",
)
#assert.eq(lens-get(resume-schema, ("work", "items")).kind, "object")
#assert.eq(lens-get(resume-schema, ("work",)).kind, "array")
// Empty path is the identity — root kind.
#assert.eq(lens-get(resume-schema, ()).kind, "object")

// Kind values (#135): a schema node matches by its kind and the fields
// it sets; a constructor stands for the kind it builds. A constructor
// finds what its no-argument node does.
#for (schema, ctor) in (
  (resume-schema, string),
  (resume-schema, bool-type),
  (resume-schema, any-of),
) {
  let found = paths-of-kind(schema, ctor)
  assert(found.len() > 0, message: repr(ctor))
}
#assert.eq(paths-of-kind(resume-schema, string), paths-of-kind(
  resume-schema,
  string(),
))

// resume-schema has no enum or not nodes, so cover every constructor
// against a toy schema where the result is non-empty.
#let kinds-toy = object((
  level: enum-of(("a", "b")),
  fixed: const-of("x"),
  either: any-of((string(), number())),
  exactly: one-of((string(), number())),
  other: not-of(string()),
  cond: if-of(bool-type, then: number()),
))
#assert.eq(paths-of-kind(kinds-toy, enum-of), (("fixed",), ("level",)))
#assert.eq(paths-of-kind(kinds-toy, const-of), (("fixed",), ("level",)))
#assert.eq(paths-of-kind(kinds-toy, any-of), (("either",), ("exactly",)))
#assert.eq(paths-of-kind(kinds-toy, one-of), (("either",), ("exactly",)))
#assert.eq(paths-of-kind(kinds-toy, not-of), (("other",),))
#assert.eq(paths-of-kind(kinds-toy, if-of), (("cond",),))

// bool-type and null-type are leaves like any other.
#let flags = object((flag: bool-type, marker: null-type, name: string()))
#assert.eq(paths-of-kind(flags, bool-type), (("flag",),))
#assert.eq(paths-of-kind(flags, null-type), (("marker",),))

// A node finds the strings that have every field it sets: string()
// every string, formatted or patterned or not; string(format: "date")
// the date strings, with a pattern or without; a node with a pattern
// the strings with that pattern.
#let strings = object((
  plain: string(),
  coded: string(pattern: "^[A-Z]{3}$"),
  email: string(format: "email"),
  dated: string(format: "date", pattern: "^2"),
))
#let every-string = (("coded",), ("dated",), ("email",), ("plain",))
#for (kind, found) in (
  (string(), every-string),
  (string, every-string),
  (string(format: "date"), (("dated",),)),
  (string(format: "email"), (("email",),)),
  (string(format: "date", pattern: "^2"), (("dated",),)),
  (string(pattern: "^[A-Z]{3}$"), (("coded",),)),
  (string(pattern: "y"), ()),
) {
  assert.eq(paths-of-kind(strings, kind), found, message: repr(kind))
}
#assert.eq(
  describe-schema(strings),
  "coded  string + pattern
dated  string (date) + pattern
email  string (email)
plain  string",
)

// The rule is the same for every kind: number(minimum: 0) finds the
// numbers whose minimum is 0, number() every number.
#let numbers = object((
  any: number(),
  low: number(minimum: 0),
  high: number(minimum: 0, maximum: 9),
  other: number(minimum: 1),
))
#assert.eq(paths-of-kind(numbers, number(minimum: 0)), (("high",), ("low",)))
#assert.eq(paths-of-kind(numbers, number()).len(), 4)
#assert.eq(
  paths-of-kind(numbers, number(minimum: 0, maximum: 9)),
  (("high",),),
)

// --- unions and `not` --------------------------------------------------

// meta.lastModified is a date-time or date string in the
// strict schema: its date member is found alongside the 13 iso8601
// fields, and the union node itself is still found.
#assert.eq(
  paths-of-kind(resume-schema-strict, string(format: "date-time")),
  (("meta", "lastModified", 0),),
)
#assert(("meta", "lastModified") in paths-of-kind(resume-schema-strict, any-of))
#assert.eq(
  lens-get(resume-schema-strict, ("meta", "lastModified", 0)).kind,
  "string",
)
#assert.eq(
  lens-get(resume-schema-strict, ("meta", "lastModified", 0)).format,
  "date-time",
)
#assert.eq(
  lens-get(resume-schema-strict, ("meta", "lastModified", 1)).format,
  "date",
)

// `location` is one-of((str, object)): its free-text member and the
// object member's fields are reachable.
#let str-paths = paths-of-kind(resume-schema, string())
#assert(("work", "items", "location", 0) in str-paths)
#assert(("work", "items", "location", 1, "city") in str-paths)
#assert.eq(
  lens-get(resume-schema, ("work", "items", "location", 1)).kind,
  "object",
)

#let union-toy = object((
  when: any-of((string(format: "date-time"), string(format: "date"))),
  place: one-of((string(), object((city: string())))),
  other: not-of(array-of(number())),
))
#assert.eq(lens-get(union-toy, ("other", "not", "items")).kind, "number")
#assert.eq(lens-get(union-toy, ("place", 1, "city")).kind, "string")
#assert.eq(paths-of-kind(union-toy, string()), (
  ("place", 0),
  ("place", 1, "city"),
  ("when", 0),
  ("when", 1),
))
#assert.eq(paths-of-kind(union-toy, number()), (("other", "not", "items"),))

// A conditional's condition and every branch are searched.
#let cond-toy = object((
  a: if-of(
    string(),
    then: object((when: string(format: "date"))),
    otherwise: array-of(string(format: "date")),
  ),
))
#assert.eq(paths-of-kind(cond-toy, string(format: "date")), (
  ("a", "then", "when"),
  ("a", "else", "items"),
))
#assert.eq(paths-of-kind(cond-toy, string()), (
  ("a", "if"),
  ("a", "then", "when"),
  ("a", "else", "items"),
))
#assert.eq(lens-get(cond-toy, ("a", "else")).kind, "array")
#for p in paths-of-kind(cond-toy, string(format: "date")) {
  assert.eq(lens-get(cond-toy, p), string(format: "date"))
}
// Every path paths-of-kind returns round-trips through a lens.
#for p in paths-of-kind(union-toy, string()) {
  assert.eq(lens-get(union-toy, p).kind, "string")
}
#for p in paths-of-kind(union-toy, string(format: "date")) {
  assert.eq(lens-get(union-toy, p), string(format: "date"))
}

// --- describe-schema: every feature it draws ----------------------------
//
// The exact output for one small schema that carries every feature, so
// a format change shows up as a diff here.

#let schema = object(
  (
    name: (..string(), min-length: 1, max-length: 80),
    email: string(format: "email"),
    phone: string(),
    age: (..integer(), minimum: 0),
    code: string(pattern: "^[A-Z]{3}$"),
    role: enum-of(("ic", "manager")),
    tags: (kind: "array", elem: string(), min-items: 1, unique-items: true),
    jobs: array-of(object(
      (title: string(), start: string(format: "date")),
      required-keys: ("title",),
    )),
    when: any-of((string(format: "date-time"), string(format: "date"))),
    place: one-of((string(), object((city: string())))),
    other: not-of(number()),
    extra: map(string()),
  ),
  required-keys: ("name", "email"),
  dependent-required: (phone: ("email",)),
)

#assert.eq(
  describe-schema(schema),
  "age     integer (minimum 0)
code    string + pattern
email*  string (email)
extra:
  *  string
jobs[]:
  start   string (date)
  title*  string
name*   string (min-length 1, max-length 80)
other:
  not  number
phone   string
place   one of:
  [0]  string
  [1]:
    city  string
role    enum (\"ic\", \"manager\")
tags[]  string (min-items 1, unique-items)
when    any of:
  [0]  string (date-time)
  [1]  string (date)
phone → email",
)

// At the root: a union's header leads, a `not` member is labelled, and
// an array's constraints follow its element.
#assert.eq(
  describe-schema(any-of((string(), array-of(number())))),
  "any of:\n  [0]    string\n  [1][]  number",
)
#assert.eq(describe-schema(not-of(object((a: string())))), "not:\n  a  string")
// A conditional labels its condition and the branches it has (the
// flat form is pinned in tests/package/reference-introspection.typ).
#assert.eq(
  describe-schema(object((a: if-of(string(), then: object((b: string())))))),
  "a:\n  if  string\n  then:\n    b  string",
)
#assert.eq(
  describe-schema((kind: "array", elem: string(), min-items: 2)),
  "[] string (min-items 2)",
)
#assert.eq(
  describe-schema(array-of(one-of((string(), number())))),
  "[] one of:\n  [0]  string\n  [1]  number",
)

// A nullable node is marked `?` after a leaf's kind, a header, or the
// label of a node drawn by its label alone, so a nullable array and an
// array of nullables differ. Only the exact (X, null-type) any-of pair
// draws as X?.
#for (schema, drawn) in (
  (nullable(string()), "string?"),
  (
    object((
      a: nullable((..string(), min-length: 1)),
      b: nullable(object((c: string()))),
      d: nullable(array-of(string())),
      e: array-of(nullable(string())),
    )),
    "a     string? (min-length 1)\nb?:\n  c  string\nd?[]  string\ne[]   string?",
  ),
  (
    object((
      d: nullable(array-of(object((c: string())))),
      e: array-of(nullable(object((c: string())))),
      u: nullable(one-of((string(), enum-of((1,))))),
    )),
    "d?[]:\n  c  string\ne[]?:\n  c  string\nu  one of?:\n  [0]  string\n  [1]  enum (1)",
  ),
  (nullable(array-of(string())), "?[] string"),
  (nullable(object((c: string()))), "?:\n  c  string"),
  (any-of((null-type, string())), "any of:\n  [0]  null\n  [1]  string"),
  (one-of((string(), null-type)), "one of:\n  [0]  string\n  [1]  null"),
) {
  assert.eq(describe-schema(schema), drawn)
}
