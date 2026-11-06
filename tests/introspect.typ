// Schema introspection: `describe-schema` draws a schema, `paths-of-kind`
// lists the lens path of every node of a kind, and `kind-at` names the
// kind at a location. All three reach into union and `not` members
// (#164): a union member's segment is its index, a `not` member's is
// "not".

#import "../lib.typ": (
  describe-schema, paths-of-kind, kind-at, lens-get, resume-schema,
  resume-schema-strict, object, array-of, map, str-type, content-type,
  number-type, integer-type, bool-type, null-type, date-string, datetime-string,
  uri-string, email-string, enum-of, pattern-string, any-of, const-of, one-of,
  not-of, nullable, string, number,
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
#assert.eq(describe-schema(str-type), "string")

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
#assert.eq(lens-get(resume-schema-strict, content-paths.at(0)), content-type)

// Formats carry through to the strict schema from the faithful
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

// Date format: only the strict overlay lifts the iso8601 $ref fields.
// Every upstream date is an iso8601 $ref now, so the faithful base
// has none.
#let date-paths-strict = paths-of-kind(resume-schema-strict, "date-string")
// The 13 _iso8601-date-paths, and meta.lastModified's date member.
#assert.eq(date-paths-strict.len(), 14)
#assert(("meta", "lastModified", 1) in date-paths-strict)
#assert(("work", "items", "startDate") in date-paths-strict)
#assert(("certificates", "items", "date") in date-paths-strict)
#assert.eq(paths-of-kind(resume-schema, "date-string"), ())

// iso8601 $ref fields land as patterned strings in the faithful base
// (translator picks up upstream's `definitions/iso8601` pattern). The
// strict overlay rewrites them to date strings, so they vanish here.
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
    ("basics", "email"),
    ("basics", "name"),
    ("basics", "url"),
    ("work", "items", "highlights", "items"),
    ("work", "items", "name"),
    ("work", "items", "startDate"),
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

// --- kind-at ---------------------------------------------------------

#assert.eq(kind-at(resume-schema, ("basics", "name")), "string")
// A formatted string is a string; its format is a field.
#assert.eq(kind-at(resume-schema, ("basics", "email")), "string")
#assert.eq(lens-get(resume-schema, ("basics", "email")).format, "email")
#assert.eq(kind-at(resume-schema-strict, ("basics", "summary")), "content")
#assert.eq(kind-at(resume-schema, ("work", "items")), "object")
#assert.eq(kind-at(resume-schema, ("work",)), "array")
// Empty path is the identity — root kind.
#assert.eq(kind-at(resume-schema, ()), "object")

// Kind values (#135): a schema node matches by its kind and the fields
// it sets; a constructor stands for the kind it builds; the name
// string still works (deprecated). Each kind is present, so no
// equality is vacuous.
#for (schema, kind, name) in (
  (resume-schema-strict, date-string, "date-string"),
  (resume-schema, pattern-string, "pattern-string"),
  (resume-schema, string(format: "uri"), "uri-string"),
  (resume-schema, str-type, "str"),
  (resume-schema, any-of, "union"),
  (resume-schema, bool-type, "bool"),
) {
  let found = paths-of-kind(schema, kind)
  assert.eq(found, paths-of-kind(schema, name), message: name)
  assert(found.len() > 0, message: name)
}

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

// bool-type and null-type are leaves like any other.
#let flags = object((flag: bool-type, marker: null-type, name: str-type))
#assert.eq(paths-of-kind(flags, "bool"), (("flag",),))
#assert.eq(paths-of-kind(flags, "null"), (("marker",),))

// A node finds the strings that have every field it sets: string()
// every string, formatted or patterned or not; string(format: "date")
// the date strings, with a pattern or without; a node with a pattern
// the strings with that pattern. A hand-built node of an old kind name
// ("str", "pattern-string", "date-string", …) is found and drawn as
// the string it now is, and its name finds what that string finds
// (deprecated, until 1.0). pattern-string, which stands for no one
// pattern, still finds every patterned string (deprecated, until 1.0).
#let strings = object((
  plain: string(),
  coded: string(pattern: "^[A-Z]{3}$"),
  old: (kind: "str"),
  old-coded: (kind: "pattern-string", pattern: regex("^x")),
  email: email-string,
  dated: string(format: "date", pattern: "^2"),
  old-dated: (kind: "date-string"),
))
#let every-string = (
  ("coded",),
  ("dated",),
  ("email",),
  ("old",),
  ("old-coded",),
  ("old-dated",),
  ("plain",),
)
#let dates = (("dated",), ("old-dated",))
#let patterned = (("coded",), ("dated",), ("old-coded",))
#for (kind, found) in (
  (string(), every-string),
  (string, every-string),
  (str-type, every-string),
  ("str", every-string),
  ((kind: "str"), every-string),
  (string(format: "date"), dates),
  (date-string, dates),
  ("date-string", dates),
  ((kind: "date-string"), dates),
  (string(format: "email"), (("email",),)),
  (string(format: "date", pattern: "^2"), (("dated",),)),
  (string(pattern: "^[A-Z]{3}$"), (("coded",),)),
  (string(pattern: "y"), ()),
  (pattern-string, patterned),
  ("pattern-string", patterned),
  ((kind: "pattern-string"), patterned),
) {
  assert.eq(paths-of-kind(strings, kind), found, message: repr(kind))
}
#assert.eq(
  describe-schema(strings),
  "coded      string + pattern
dated      string (date) + pattern
email      string (email)
old        string
old-coded  string + pattern
old-dated  string (date)
plain      string",
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
  paths-of-kind(resume-schema-strict, datetime-string),
  (("meta", "lastModified", 0),),
)
#assert(("meta", "lastModified") in paths-of-kind(resume-schema-strict, any-of))
#assert.eq(
  kind-at(resume-schema-strict, ("meta", "lastModified", 0)),
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
#let str-paths = paths-of-kind(resume-schema, str-type)
#assert(("work", "items", "location", 0) in str-paths)
#assert(("work", "items", "location", 1, "city") in str-paths)
#assert.eq(kind-at(resume-schema, ("work", "items", "location", 1)), "object")

#let union-toy = object((
  when: any-of((datetime-string, date-string)),
  place: one-of((str-type, object((city: str-type)))),
  other: not-of(array-of(number-type)),
))
#assert.eq(kind-at(union-toy, ("other", "not", "items")), "number")
#assert.eq(kind-at(union-toy, ("place", 1, "city")), "string")
#assert.eq(paths-of-kind(union-toy, str-type), (
  ("place", 0),
  ("place", 1, "city"),
  ("when", 0),
  ("when", 1),
))
#assert.eq(paths-of-kind(union-toy, number-type), (("other", "not", "items"),))
// Every path paths-of-kind returns round-trips through a lens.
#for p in paths-of-kind(union-toy, str-type) {
  assert.eq(lens-get(union-toy, p).kind, "string")
}
#for p in paths-of-kind(union-toy, date-string) {
  assert.eq(lens-get(union-toy, p), date-string)
}

// --- describe-schema: every feature it draws ----------------------------
//
// The exact output for one small schema that carries every feature, so
// a format change shows up as a diff here.

#let schema = object(
  (
    name: (..str-type, min-length: 1, max-length: 80),
    email: email-string,
    phone: str-type,
    age: (..integer-type, minimum: 0),
    code: pattern-string("^[A-Z]{3}$"),
    role: enum-of(("ic", "manager")),
    tags: (kind: "array", elem: str-type, min-items: 1, unique-items: true),
    jobs: array-of(object(
      (title: str-type, start: date-string),
      required-keys: ("title",),
    )),
    when: any-of((datetime-string, date-string)),
    place: one-of((str-type, object((city: str-type)))),
    other: not-of(number-type),
    extra: map(str-type),
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
  describe-schema(any-of((str-type, array-of(number-type)))),
  "any of:\n  [0]    string\n  [1][]  number",
)
#assert.eq(describe-schema(not-of(object((a: str-type)))), "not:\n  a  string")
#assert.eq(
  describe-schema((kind: "array", elem: str-type, min-items: 2)),
  "[] string (min-items 2)",
)
#assert.eq(
  describe-schema(array-of(one-of((str-type, number-type)))),
  "[] one of:\n  [0]  string\n  [1]  number",
)

// A nullable node is marked `?` after a leaf's kind, a header, or the
// label of a node drawn by its label alone, so a nullable array and an
// array of nullables differ. Only the exact (X, null-type) any-of pair
// draws as X?.
#for (schema, drawn) in (
  (nullable(str-type), "string?"),
  (
    object((
      a: nullable((..str-type, min-length: 1)),
      b: nullable(object((c: str-type))),
      d: nullable(array-of(str-type)),
      e: array-of(nullable(str-type)),
    )),
    "a     string? (min-length 1)\nb?:\n  c  string\nd?[]  string\ne[]   string?",
  ),
  (
    object((
      d: nullable(array-of(object((c: str-type)))),
      e: array-of(nullable(object((c: str-type)))),
      u: nullable(one-of((str-type, enum-of((1,))))),
    )),
    "d?[]:\n  c  string\ne[]?:\n  c  string\nu  one of?:\n  [0]  string\n  [1]  enum (1)",
  ),
  (nullable(array-of(str-type)), "?[] string"),
  (nullable(object((c: str-type))), "?:\n  c  string"),
  (any-of((null-type, str-type)), "any of:\n  [0]  null\n  [1]  string"),
  (one-of((str-type, null-type)), "one of:\n  [0]  string\n  [1]  null"),
) {
  assert.eq(describe-schema(schema), drawn)
}
