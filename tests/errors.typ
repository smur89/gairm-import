// What validate reports: every error is a `(path, code, message,
// expected, got)` record, its message renders JSON type names, an
// unknown key suggests the closest valid one, and format-errors turns
// the list into parse's report.

#import "../lib.typ": (
  validate, format-errors, boolean, null, array-of, object, enum-of, any-of,
  one-of, not-of, string, number, integer,
)

// ---- one record per code ---------------------------------------------
//
// Each row: the value, the schema, then the one error's code, path,
// expected and got.

#let clock = datetime(hour: 10, minute: 0, second: 0)
#let numbers = array-of(number())
#for (value, schema, code, path, expected, got) in (
  // type
  ((a: 1), object((a: string())), "type", ("a",), "string", "integer"),
  ("x", number(), "type", (), "number", "string"),
  (1, boolean(), "type", (), "boolean", "integer"),
  (1, null(), "type", (), "null", "integer"),
  (1, array-of(string()), "type", (), "array", "integer"),
  (1, object((:)), "type", (), "object", "integer"),
  (1, string(format: "email"), "type", (), "string", "integer"),
  // An enum none of whose values shares the value's type: the JSON
  // type names its values have.
  (true, enum-of(("a", "b")), "type", (), "string", "boolean"),
  // A union none of whose members takes the value's type: the JSON
  // type names their own type errors give. A null member judges no
  // non-null value by default, so it names none.
  (
    true,
    any-of((string(), number())),
    "type",
    (),
    "string or number",
    "boolean",
  ),
  (
    true,
    any-of((integer(), enum-of((1, "a")), any-of((string(), null())))),
    "type",
    (),
    "integer or number or string",
    "boolean",
  ),
  ("x", integer(), "type", (), "integer", "string"),
  // required
  (
    (:),
    object((a: string()), required-keys: ("a",)),
    "required",
    ("a",),
    none,
    none,
  ),
  // unknown-key
  (
    (b: 1),
    object((a: string(), c: string())),
    "unknown-key",
    ("b",),
    (
      "a",
      "c",
    ),
    "b",
  ),
  // dependent
  (
    (a: "x"),
    object((a: string(), b: string()), dependent-required: (a: ("b",))),
    "dependent",
    ("b",),
    (dependent-required: (a: ("b",))),
    none,
  ),
  // enum; int and float are one JSON number type, so 2.5 is an enum miss.
  ("c", enum-of(("a", "b")), "enum", (), ("a", "b"), "c"),
  (2.5, enum-of((1, 2)), "enum", (), (1, 2), 2.5),
  // format
  (
    "nope",
    string(format: "email"),
    "format",
    (),
    "an email (e.g. \"name@example.com\")",
    "nope",
  ),
  // A datetime that can't be written as a date is a format failure,
  // not a type one: the kind takes datetimes.
  (
    clock,
    string(format: "date"),
    "format",
    (),
    "a string or a datetime with a date and no time",
    clock,
  ),
  // pattern
  (
    "abc",
    string(pattern: "^[0-9]+$", expected: "digits"),
    "pattern",
    (),
    "digits",
    "abc",
  ),
  (
    "a@b.com",
    (..string(format: "email"), pattern: regex("^z"), expected: "a z-address"),
    "pattern",
    (),
    "a z-address",
    "a@b.com",
  ),
  // length
  ("ab", (kind: "string", min-length: 3), "length", (), (min-length: 3), 2),
  ("abcd", (kind: "string", max-length: 3), "length", (), (max-length: 3), 4),
  // range: the record says which bound, not just the number.
  (0, (kind: "number", minimum: 1), "range", (), (minimum: 1), 0),
  (5, (kind: "number", maximum: 4), "range", (), (maximum: 4), 5),
  (
    1,
    (kind: "number", exclusive-minimum: 1),
    "range",
    (),
    (
      exclusive-minimum: 1,
    ),
    1,
  ),
  (
    4,
    (kind: "number", exclusive-maximum: 4),
    "range",
    (),
    (
      exclusive-maximum: 4,
    ),
    4,
  ),
  // multiple
  (7, (kind: "number", multiple-of: 3), "multiple", (), (multiple-of: 3), 7),
  // integer
  ((n: 1.5), object((n: integer())), "integer", ("n",), none, 1.5),
  // items
  ((1,), (..numbers, min-items: 2), "items", (), (min-items: 2), 1),
  ((1, 2, 3), (..numbers, max-items: 2), "items", (), (max-items: 2), 3),
  // unique
  ((1, 2, 1), (..numbers, unique-items: true), "unique", (), none, (0, 2)),
  // union: several members claim a string and none matches; a one-of
  // with more than one match.
  (
    "x",
    any-of((enum-of(("a",)), string(format: "email"))),
    "union",
    (),
    (
      "enum (\"a\")",
      "string (email)",
    ),
    none,
  ),
  (
    1,
    one-of((number(), enum-of((1, 2)))),
    "union",
    (),
    (
      "number",
      "enum (1, 2)",
    ),
    none,
  ),
  // not
  ("x", not-of(string()), "not", (), none, none),
) {
  let errs = validate(schema, value)
  assert.eq(errs.len(), 1, message: repr(errs))
  let e = errs.first()
  assert.eq(e.keys().sorted(), ("code", "expected", "got", "message", "path"))
  assert.eq(
    (e.code, e.path, e.expected, e.got),
    (code, path, expected, got),
    message: repr(value),
  )
}

// ---- messages name JSON types ----------------------------------------
//
// A type mismatch reads "expected <type>, got <type>." with JSON's
// names, not Typst's (int, dictionary, type(none)), so README samples
// and runtime output stay in lockstep.

#for (schema, value, message) in (
  (string(), 42, "expected string, got integer."),
  (string(), 3.14, "expected string, got number."),
  (string(), true, "expected string, got boolean."),
  (string(), (1,), "expected string, got array."),
  (string(), (a: 1), "expected string, got object."),
  (number(), "nope", "expected number, got string."),
  (array-of(string()), "x", "expected array, got string."),
  (object((name: string())), "x", "expected object, got string."),
) {
  assert.eq(
    validate(object((f: schema)), (f: value)).map(e => e.message),
    (message,),
  )
}
// Null is absent by default; strict-null judges it and names it.
#assert.eq(validate(object((f: string())), (f: none)), ())
#assert.eq(
  validate(object((f: string())), (f: none), strict-null: true).first().message,
  "expected string, got null.",
)

// ---- unknown keys suggest the closest valid key ----------------------
//
// The suggestion is the key fewest edits away (Levenshtein), within
// two edits inclusive (one for a key of up to three characters, where
// two reach almost anything), the first declared winning a tie.

#let suggestion(key, keys) = {
  let shape = keys.map(k => (k, string())).to-dict()
  let message = validate(object(shape), ((key): 1)).first().message
  let hint = message.find(regex("Did you mean \"[^\"]*\"\\?"))
  if hint == none { none } else { hint.slice(14, -2) }
}

#for (key, keys, expected) in (
  ("postion", ("name", "position", "url"), "position"), // one insertion
  ("positon", ("name", "position", "url"), "position"), // one missing letter
  ("psoition", ("name", "position", "url"), "position"), // transposition: 2 edits
  ("enmail", ("name", "email", "phone"), "email"), // one extra letter
  ("nme", ("name", "email"), "name"), // the closer of two
  ("abcd", ("xycd",), "xycd"), // exactly two edits still suggests
  ("abcd", ("xyzd",), none), // three edits does not
  ("ab", ("xy",), none), // two edits on a short key is too far
  ("a", ("id",), none),
  ("nam", ("name",), "name"), // one edit on a short key suggests
  ("contact", ("name", "email", "phone"), none),
  ("anything", (), none), // no keys to suggest
  // A tie goes to the key declared first.
  ("ab", ("xb", "ay"), "xb"),
  ("ab", ("ay", "xb"), "ay"),
) {
  assert.eq(suggestion(key, keys), expected, message: key + " in " + repr(keys))
}

// ---- format-errors ---------------------------------------------------

// Each error is a line: the path rendered, then the message.
#for (path, rendered) in (
  ((), "<root>"),
  (("basics",), "basics"),
  (("basics", "email"), "basics.email"),
  (("work", 0), "work[0]"),
  (("work", 0, "position"), "work[0].position"),
  (("work", 0, "highlights", 2), "work[0].highlights[2]"),
) {
  assert(
    format-errors(((path: path, message: "m."),)).contains(
      "\n  - " + rendered + ": m.",
    ),
    message: rendered,
  )
}

#let one = format-errors((
  (path: ("basics", "email"), message: "expected string, got integer."),
))
#assert(one.contains("1 problem"))
#assert(one.contains("basics.email: expected string"))

#let many = format-errors((
  (path: ("basics", "email"), message: "expected string, got integer."),
  (path: ("work", 0, "positon"), message: "unknown key \"positon\"."),
))
#assert(many.contains("2 problems"))
#assert(many.contains("basics.email"))
#assert(many.contains("work[0].positon"))

// ---- path rendering -----------------------------------------------------
//
// A key that would read ambiguously after a dot is quoted in brackets,
// so `("a.b", "c")` and `("a", "b", "c")` never render alike.
#assert.eq(
  format-errors((
    (path: ("a.b", "c"), message: "m."),
    (path: ("a", "b", "c"), message: "m."),
    (path: ("", 0, "x y"), message: "m."),
    (path: ("naïve-key_1",), message: "m."),
    (path: (), message: "m."),
  )),
  "gairm-import: found 5 problems in the input:\n"
    + "  - [\"a.b\"].c: m.\n"
    + "  - a.b.c: m.\n"
    + "  - [\"\"][0][\"x y\"]: m.\n"
    + "  - naïve-key_1: m.\n"
    + "  - <root>: m.",
)
