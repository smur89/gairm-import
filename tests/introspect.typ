// Schema introspection: `describe-schema` draws a schema, `find-paths`
// lists the schema path of every node of a kind. Both reach into union
// and `not` members
// (#164) and conditionals (#109): a union member's segment is its
// index, a `not` member's is "not", and a conditional's are "if",
// "then" and "else".

#import "../lib.typ": (
  describe-schema, find-paths, schema-get, object, array-of, map, markup,
  boolean, null, enum-of, any-of, const-of, one-of, not-of, if-of, nullable,
  string, number, integer, schema-from-json-schema,
)
#import "fixtures/resume.typ": resume-schema, resume-schema-strict

// --- describe-schema -------------------------------------------------

// Nested objects, leaf alignment, array-of-object header, array-of-leaf
// inline. Alphabetical key ordering pinned via the expected blob.
#let toy = object((
  basics: object((
    name: string(),
    summary: markup(),
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
  summary  markup
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

// --- find-paths ---------------------------------------------------

// The strict schema's content leaves are the fixture's content-paths
// (14 entries). Alphabetical ordering means we can pin the exact list.
#let content-paths = find-paths(resume-schema-strict, markup())
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

// `items` segments are schema paths — feed one back in.
#assert.eq(schema-get(resume-schema-strict, content-paths.at(0)), markup())

// Formats carry through to the strict schema from the faithful
// base (translator-emitted `format: "uri"` / `format: "email"`).
// Full URI path list pinned so a translator regression surfaces here.
#assert.eq(find-paths(resume-schema-strict, string(format: "uri")), (
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
  find-paths(resume-schema-strict, string(format: "email")),
  (("basics", "email"),),
)

// Date format: only the strict schema lifts the iso8601 $ref fields.
// Every upstream date is an iso8601 $ref now, so the faithful base
// has none.
#let date-paths-strict = find-paths(
  resume-schema-strict,
  string(format: "date"),
)
// The full-date member of each of the 13 iso8601 $ref fields.
#assert.eq(date-paths-strict.len(), 13)
#assert(date-paths-strict.all(p => p.last() == 0))
#assert(("work", "items", "startDate", 0) in date-paths-strict)
#assert(("certificates", "items", "date", 0) in date-paths-strict)
#assert.eq(find-paths(resume-schema, string(format: "date")), ())

// iso8601 $ref fields land as patterned strings in the faithful base
// (translator picks up upstream's `definitions/iso8601` pattern). The
// strict schema rewrites them to date strings, so they vanish there.
// The query is one of them, so it finds every string with that pattern.
#let iso8601 = schema-get(resume-schema, ("work", "items", "startDate"))
#let iso-paths-faithful = find-paths(resume-schema, iso8601)
#assert.eq(iso-paths-faithful.len(), 13)
#assert(("work", "items", "startDate") in iso-paths-faithful)
#assert(("publications", "items", "releaseDate") in iso-paths-faithful)
#assert.eq(find-paths(resume-schema-strict, iso8601), ())

// Empty schema yields an empty result.
#assert.eq(find-paths(object((:)), string()), ())

// Toy schema — confirm path tuples for a hand-built nested case.
#assert.eq(
  find-paths(toy, string(format: "uri")),
  (("basics", "url"),),
)
#assert.eq(
  find-paths(toy, string()),
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
  find-paths(toy, string(format: "date")),
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

// Three levels deep with markup() at the leaf.
#let cube-schema = object((
  cube: array-of(array-of(array-of(markup()))),
))
#assert.eq(
  describe-schema(cube-schema),
  "cube[]:\n  []:\n    [] markup",
)

// --- the kind at a location ----------------------------------------

#assert.eq(schema-get(resume-schema, ("basics", "name")).kind, "string")
// A formatted string is a string; its format is a field.
#assert.eq(schema-get(resume-schema, ("basics", "email")).kind, "string")
#assert.eq(schema-get(resume-schema, ("basics", "email")).format, "email")
#assert.eq(
  schema-get(resume-schema-strict, ("basics", "summary")).kind,
  "markup",
)
#assert.eq(schema-get(resume-schema, ("work", "items")).kind, "object")
#assert.eq(schema-get(resume-schema, ("work",)).kind, "array")
// Empty path is the identity — root kind.
#assert.eq(schema-get(resume-schema, ()).kind, "object")

// Kind values (#135): a schema node matches by its kind and the fields
// it sets; a constructor stands for the kind it builds. A constructor
// finds what its no-argument node does.
#for (schema, ctor) in (
  (resume-schema, string),
  (resume-schema, boolean()),
  (resume-schema, one-of),
) {
  let found = find-paths(schema, ctor)
  assert(found.len() > 0, message: repr(ctor))
}
#assert.eq(find-paths(resume-schema, string), find-paths(
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
  maybe: nullable(string()),
  other: not-of(string()),
  cond: if-of(boolean(), then: number()),
))
#assert.eq(find-paths(kinds-toy, enum-of), (("fixed",), ("level",)))
// A constructor finds the nodes it builds, narrower than its kind:
// const-of the single-value enums, any-of the inclusive unions (a
// nullable is one), one-of the exclusive ones, nullable the nullables.
#assert.eq(find-paths(kinds-toy, const-of), (("fixed",),))
#assert.eq(find-paths(kinds-toy, any-of), (("either",), ("maybe",)))
#assert.eq(find-paths(kinds-toy, one-of), (("exactly",),))
#assert.eq(find-paths(kinds-toy, nullable), (("maybe",),))
#assert.eq(find-paths(kinds-toy, not-of), (("other",),))
#assert.eq(find-paths(kinds-toy, if-of), (("cond",),))

// boolean() and null() are leaves like any other.
#let flags = object((flag: boolean(), marker: null(), name: string()))
#assert.eq(find-paths(flags, boolean()), (("flag",),))
#assert.eq(find-paths(flags, null()), (("marker",),))

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
  assert.eq(find-paths(strings, kind), found, message: repr(kind))
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
#assert.eq(find-paths(numbers, number(minimum: 0)), (("high",), ("low",)))
#assert.eq(find-paths(numbers, number()).len(), 4)
#assert.eq(
  find-paths(numbers, number(minimum: 0, maximum: 9)),
  (("high",),),
)

// --- unions and `not` --------------------------------------------------

// A strict date field is a full date or a partial one: the union node
// is found, and schema-get reaches each member.
#assert(
  ("work", "items", "startDate") in find-paths(resume-schema-strict, any-of),
)
#assert.eq(
  schema-get(resume-schema-strict, ("work", "items", "startDate", 0)).format,
  "date",
)
#assert.eq(
  schema-get(resume-schema-strict, ("work", "items", "startDate", 1)).kind,
  "string",
)

// `location` is one-of((str, object)): its free-text member and the
// object member's fields are reachable.
#let str-paths = find-paths(resume-schema, string())
#assert(("work", "items", "location", 0) in str-paths)
#assert(("work", "items", "location", 1, "city") in str-paths)
#assert.eq(
  schema-get(resume-schema, ("work", "items", "location", 1)).kind,
  "object",
)

#let union-toy = object((
  when: any-of((string(format: "date-time"), string(format: "date"))),
  place: one-of((string(), object((city: string())))),
  other: not-of(array-of(number())),
))
#assert.eq(schema-get(union-toy, ("other", "not", "items")).kind, "number")
#assert.eq(schema-get(union-toy, ("place", 1, "city")).kind, "string")
#assert.eq(find-paths(union-toy, string()), (
  ("place", 0),
  ("place", 1, "city"),
  ("when", 0),
  ("when", 1),
))
#assert.eq(find-paths(union-toy, number()), (("other", "not", "items"),))

// A conditional's condition and every branch are searched.
#let cond-toy = object((
  a: if-of(
    string(),
    then: object((when: string(format: "date"))),
    otherwise: array-of(string(format: "date")),
  ),
))
#assert.eq(find-paths(cond-toy, string(format: "date")), (
  ("a", "then", "when"),
  ("a", "else", "items"),
))
#assert.eq(find-paths(cond-toy, string()), (
  ("a", "if"),
  ("a", "then", "when"),
  ("a", "else", "items"),
))
#assert.eq(schema-get(cond-toy, ("a", "else")).kind, "array")
#for p in find-paths(cond-toy, string(format: "date")) {
  assert.eq(schema-get(cond-toy, p), string(format: "date"))
}
// Every path find-paths returns round-trips through schema-get.
#for p in find-paths(union-toy, string()) {
  assert.eq(schema-get(union-toy, p).kind, "string")
}
#for p in find-paths(union-toy, string(format: "date")) {
  assert.eq(schema-get(union-toy, p), string(format: "date"))
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
// array of nullables differ. Only the exact (X, null()) any-of pair
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
  (any-of((null(), string())), "any of:\n  [0]  null\n  [1]  string"),
  (one-of((string(), null())), "one of:\n  [0]  string\n  [1]  null"),
) {
  assert.eq(describe-schema(schema), drawn)
}

// Columns line up by grapheme cluster, not byte: `seán` and `名前`
// pad as four and two characters wide.
#assert.eq(
  describe-schema(object((sean: string(), "seán": number(), "名前": string()))),
  "sean  string\nseán  number\n名前    string",
)

// A hand-built union of nullable's shape is a nullable to the query.
#assert.eq(
  find-paths(
    object((
      a: (kind: "union", members: (string(), null()), exclusive: false),
    )),
    nullable,
  ),
  (("a",),),
)
#assert.eq(find-paths(object((a: nullable(string()))), nullable), (("a",),))

// string(pattern:) sets no `expected`, so a query by pattern alone finds
// a custom message and the translator's `matching "^x"` alike; one that
// sets `expected` narrows by it, as any other field does.
#let patterned = object((
  a: string(pattern: "^x", expected: "an x"),
  b: schema-from-json-schema((type: "string", pattern: "^x")),
  c: string(pattern: "^y"),
))
#assert.eq(find-paths(patterned, string(pattern: "^x")), (("a",), ("b",)))
#assert.eq(
  find-paths(patterned, string(pattern: "^x", expected: "an x")),
  (("a",),),
)
// An additional schema shadowed by a literal "additionalProperties"
// field has no path, so none is returned for it.
#let shadowed = object(
  (additionalProperties: any-of(string(), number())),
  additional: one-of(string(), number()),
)
#assert.eq(find-paths(shadowed, one-of), ())
#assert.eq(find-paths(shadowed, any-of), (("additionalProperties",),))

// A key that doesn't read plainly is quoted, a nullable of a nullable
// draws as one `?`, and a dependent-required trigger with no dependents
// is dropped (object() drops it).
#let edge = object(
  ("": string(), "a.b": nullable(nullable(string())), c: string()),
  dependent-required: (c: (), "a.b": ("",)),
)
#assert.eq(edge.dependent-required, ("a.b": ("",)))
#assert.eq(
  describe-schema(edge),
  "\"\"     string\n\"a.b\"  string?\nc      string\n\"a.b\" → \"\"",
)
