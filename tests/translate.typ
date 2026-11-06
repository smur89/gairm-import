// schema-from-json-schema: each JSON Schema (draft 7 subset) construct
// and the node it builds. The canonical JSON Resume document is
// covered in tests/resume-schema.typ, and what the translator rejects
// in tests/panics/.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, str-type, number-type,
  integer-type, bool-type, null-type, any-type, array-of, object, date-string,
  datetime-string, uri-string, email-string, uuid-string, hostname-string,
  ipv4-string, ipv6-string, time-string, pattern-string, enum-of, const-of,
  any-of, one-of, not-of, nullable, number, describe-schema,
)

#let T = schema-from-json-schema
#let x-gate = (pattern: regex("^x$"), expected: "matching " + repr("^x$"))

// ---- one node per construct ----------------------------------------------

#for (js, node) in (
  // Types. `integer` keeps its integral gate rather than flattening to
  // number, which would silently drop the constraint.
  ((type: "string"), str-type),
  ((type: "number"), number-type),
  ((type: "integer"), integer-type),
  ((type: "boolean"), bool-type),
  ((type: "null"), null-type),
  ((type: "array", items: (type: "string")), array-of(str-type)),
  (
    (type: "array", items: (type: "array", items: (type: "number"))),
    array-of(array-of(number-type)),
  ),
  // Formats map to their string kinds.
  ((type: "string", format: "uri"), uri-string),
  ((type: "string", format: "email"), email-string),
  ((type: "string", format: "date"), date-string),
  ((type: "string", format: "date-time"), datetime-string),
  ((type: "string", format: "uuid"), uuid-string),
  ((type: "string", format: "hostname"), hostname-string),
  ((type: "string", format: "ipv4"), ipv4-string),
  ((type: "string", format: "ipv6"), ipv6-string),
  ((type: "string", format: "time"), time-string),
  // A pattern is a patterned string with a hint naming it (regexes compare
  // by source). With a format, the format kind carries it as an extra
  // gate.
  (
    (type: "string", pattern: "^[A-Z]{2}$"),
    pattern-string("^[A-Z]{2}$", expected: "matching " + repr("^[A-Z]{2}$")),
  ),
  ((type: "string", format: "email", pattern: "^x$"), email-string + x-gate),
  ((type: "string", format: "uri", pattern: "^x$"), uri-string + x-gate),
  ((type: "string", format: "date", pattern: "^x$"), date-string + x-gate),
  (
    (type: "string", format: "date-time", pattern: "^x$"),
    datetime-string + x-gate,
  ),
  // `[X, "null"]` is nullable(X), whichever comes first; X keeps its
  // own keywords. A repeated type is one.
  ((type: ("string", "null")), nullable(str-type)),
  ((type: ("null", "integer")), nullable(integer-type)),
  ((type: ("string", "null"), format: "email"), nullable(email-string)),
  ((type: ("string", "string", "null")), nullable(str-type)),
  // A `type` array builds each member from the whole node, each ignoring
  // the other types' keywords, as in draft 7.
  (
    (type: ("string", "number"), minimum: 1),
    any-of((str-type, number(minimum: 1))),
  ),
  // enum maps to enum-of whatever the `type`, values verbatim; const to
  // const-of, the singleton enum.
  ((enum: ("a", "b", "c")), enum-of(("a", "b", "c"))),
  ((type: "string", enum: ("a", "b")), enum-of(("a", "b"))),
  ((enum: (1, "two", 3.0)), enum-of((1, "two", 3.0))),
  ((enum: ()), enum-of(())),
  ((const: "v1.0.0"), const-of("v1.0.0")),
  ((type: "string", const: "fixed"), const-of("fixed")),
  // A null is a value where null means something: `const: null`, an
  // `enum` member, an annotation. Beside any other keyword it panics.
  ((const: none), enum-of((none,))),
  ((enum: ("a", none)), enum-of(("a", none))),
  (
    (
      type: "string",
      title: none,
      description: none,
      default: none,
      examples: none,
    ),
    str-type,
  ),
  // Keywords beside enum / const fold into the value set: only values
  // that satisfy them survive. A keyword for another type ignores the
  // values it doesn't apply to.
  ((enum: (1, 5, 20), minimum: 4), enum-of((5, 20))),
  ((enum: ("a", "bb", "ccc"), minLength: 2, maxLength: 2), enum-of(("bb",))),
  ((enum: ("ab1", "abc", "x"), pattern: "^ab"), enum-of(("ab1", "abc"))),
  ((type: "integer", enum: (1.5, 2, 3.0)), enum-of((2, 3.0))),
  ((type: "string", enum: ("a", 1)), enum-of(("a",))),
  ((type: ("string", "null"), enum: ("a", 1, none)), enum-of(("a", none))),
  (
    (enum: ("a@x.io", "b@y.io", "nope"), format: "email", pattern: "^a"),
    enum-of(("a@x.io",)),
  ),
  ((enum: ((1,), (1, 2), (3,)), minItems: 2), enum-of(((1, 2),))),
  ((const: 5, minimum: 4), const-of(5)),
  ((enum: (1, "x", true, none), minimum: 4), enum-of(("x", true, none))),
  // anyOf / oneOf / not, nested too.
  (
    (anyOf: ((type: "string"), (type: "number"))),
    any-of((str-type, number-type)),
  ),
  (
    (oneOf: ((type: "string"), (type: "boolean"))),
    one-of((str-type, bool-type)),
  ),
  (("not": (type: "string")), not-of(str-type)),
  (
    (anyOf: ((type: "string"), (oneOf: ((type: "number"), (type: "boolean"))))),
    any-of((str-type, one-of((number-type, bool-type)))),
  ),
  // No `type`: `{}` and annotations alone take any value; a keyword
  // narrows only its own type's member.
  ((:), any-type),
  ((title: "x", description: "anything"), any-type),
  ((type: "array"), array-of(any-type)),
  ((type: "array", minItems: 1), (..array-of(any-type), min-items: 1)),
  (
    (minLength: 2),
    any-of((
      bool-type,
      object((:), additional: true),
      array-of(any-type),
      number-type,
      (..str-type, min-length: 2),
      null-type,
    )),
  ),
  // Every entry form: a dict, or bytes as Typst's decoders take.
  (bytes("{\"type\": \"string\"}"), str-type),
) {
  assert.eq(T(js), node, message: repr(js))
}

// ---- objects ---------------------------------------------------------------

#let person = T((
  type: "object",
  properties: (name: (type: "string"), age: (type: "integer")),
  required: ("name",),
))
#assert.eq(person, object(
  (name: str-type, age: integer-type),
  required-keys: ("name",),
))
#assert.eq(
  T((type: "object", properties: (a: (type: "string")))).required-keys,
  (),
)
// `properties: (:)` is the closed empty object; leaving it out is an
// open object, which panics.
#assert.eq(T((type: "object", properties: (:))), object((:)))
#assert.eq(
  T((type: "object", properties: (anything: (:)))).shape.anything,
  any-type,
)

// ---- $ref ------------------------------------------------------------------

// Into definitions or $defs, chained, under properties or items.
#let resolved = T((
  definitions: (
    alias: ("$ref": "#/definitions/iso8601"),
    iso8601: (type: "string"),
  ),
  type: "object",
  properties: (
    startDate: ("$ref": "#/definitions/iso8601"),
    viaAlias: ("$ref": "#/definitions/alias"),
    summary: (type: "string"),
  ),
))
#assert.eq(resolved.shape, (
  startDate: str-type,
  viaAlias: str-type,
  summary: str-type,
))
#assert.eq(
  T((
    "$defs": (item: (type: "string")),
    type: "array",
    items: ("$ref": "#/$defs/item"),
  )),
  array-of(str-type),
)

// $ref is an RFC 6901 pointer: `~1` is `/`, `~0` is `~`, and a numeric
// segment indexes an array. (An empty segment is the "" key, so a
// trailing slash does not resolve.) It is also a URI fragment, so it is
// percent-decoded first (RFC 3986); adapted from the JSON Schema test
// suite's "refs with quote" and "$ref to key containing percent".
#let refs = T((
  definitions: (
    "a/b": (type: "string"),
    "a~b": (type: "number"),
    pair: (anyOf: ((type: "string"), (type: "integer"))),
    "a%b": (type: "string"),
    "a\"b": (type: "number"),
    "a~b c": (type: "boolean"),
    plain: (type: "integer"),
    "café": (type: "string"),
  ),
  type: "object",
  properties: (
    slash: ("$ref": "#/definitions/a~1b"),
    tilde: ("$ref": "#/definitions/a~0b"),
    indexed: ("$ref": "#/definitions/pair/anyOf/1"),
    utf8: ("$ref": "#/definitions/caf%C3%a9"),
    percent: ("$ref": "#/definitions/a%25b"),
    quote: ("$ref": "#/definitions/a%22b"),
    tilde-space: ("$ref": "#/definitions/a~0b%20c"),
    plain: ("$ref": "#/definitions/plain"),
  ),
))
#assert.eq(refs.shape, (
  slash: str-type,
  tilde: number-type,
  indexed: integer-type,
  utf8: str-type,
  percent: str-type,
  quote: number-type,
  tilde-space: bool-type,
  plain: integer-type,
))

// The edges of the lead bytes whose second byte is narrowed (RFC 3629
// §4) still decode; one past each is a malformed escape.
#for (escaped, key) in (
  "%E0%A0%80": "\u{800}",
  "%ED%9F%BF": "\u{D7FF}",
  "%F0%90%80%80": "\u{10000}",
  "%F4%8F%BF%BF": "\u{10FFFF}",
) {
  assert.eq(
    T((
      definitions: ((key): (type: "string")),
      "$ref": "#/definitions/" + escaped,
    )),
    str-type,
  )
}

// ---- allOf: the object-merge subset ---------------------------------------

// Shapes and required keys union; a single member is the identity;
// equal duplicate properties merge; $refs resolve against the root;
// annotations beside allOf are tolerated.
#let obj(props, ..rest) = (type: "object", properties: props, ..rest.named())
#for (members, extra, node) in (
  (
    (
      obj((name: (type: "string")), required: ("name",)),
      obj((age: (type: "integer")), required: ("age",)),
    ),
    (:),
    object((name: str-type, age: integer-type), required-keys: ("name", "age")),
  ),
  ((obj((a: (type: "string"))),), (:), object((a: str-type))),
  (
    (
      obj((a: (type: "string"))),
      obj((a: (type: "string"), b: (type: "number"))),
    ),
    (:),
    object((a: str-type, b: number-type)),
  ),
  (
    (("$ref": "#/definitions/base"), obj((extra: (type: "number")))),
    (definitions: (base: obj((id: (type: "string"))))),
    object((id: str-type, extra: number-type)),
  ),
  (
    (obj((a: (type: "string"))),),
    (title: "combined", description: "docs only"),
    object((a: str-type)),
  ),
  // additionalProperties must agree across every member (an undeclared
  // one counts as closed): open members merge open.
  (
    (
      obj((a: (type: "string")), additionalProperties: true),
      obj((b: (type: "number")), additionalProperties: true),
    ),
    (:),
    object((a: str-type, b: number-type), additional: true),
  ),
  // Closed or typed members merge when they declare the same
  // properties, so each one's additionalProperties sees the same extras.
  (
    (
      obj((a: (type: "string")), additionalProperties: false),
      obj((a: (type: "string")), required: ("a",), additionalProperties: false),
    ),
    (:),
    object((a: str-type), required-keys: ("a",)),
  ),
  (
    (
      obj((a: (type: "string")), additionalProperties: (type: "number")),
      obj((a: (type: "string")), additionalProperties: (type: "number")),
    ),
    (:),
    object((a: str-type), additional: number-type),
  ),
) {
  assert.eq(T((allOf: members, ..extra)), node, message: repr(members))
}

// ---- a node without `type` -------------------------------------------------
//
// Draft 7: `{}` takes any value, and a type-specific keyword constrains
// only values of its own type. Adapted from the JSON Schema test suite.

#assert.eq(describe-schema(any-type), "any")

// One value of every JSON type, and some nesting.
#let every-type = (
  none,
  true,
  false,
  0,
  -1.5,
  "",
  "a",
  (),
  (1, "a", none),
  (:),
  (a: (b: none)),
)

// Under an optional field, so null can be tried in both modes.
#let check(js, value, strict, valid) = {
  let errs = validate(
    (x: value),
    schema: object((x: T(js))),
    strict-null: strict,
  )
  assert.eq(
    errs.len() == 0,
    valid,
    message: repr(js)
      + " on "
      + repr(value)
      + " (strict-null: "
      + repr(strict)
      + "): "
      + repr(errs),
  )
}

#let props = (properties: (a: (type: "string")))
#let deps = (dependencies: (a: ("b",)))
#for strict in (false, true) {
  // {} accepts every value.
  for v in every-type {
    check((:), v, strict, true)
    check((type: "object", properties: (x: (:))), (x: v), strict, true)
  }
  // Each row: a keyword with no type, the values it rejects, and values
  // it takes, of its own type and of others.
  for (js, bad, good) in (
    ((minLength: 2), ("a",), ("ab", 1, none, (), (:), true)),
    ((format: "date"), ("x",), ("2024-01-15", 1, none, ("x",))),
    ((minimum: 1), (0,), (1, "a", none, (0,))),
    ((items: (type: "string")), ((1,),), (("a",), 1, "a")),
    // properties without type: objects only, closed like a typed object
    // with properties and no additionalProperties.
    (props, ((a: 1), (b: "x")), ((a: "x"), (:), "x", 1, none, (1,))),
    // required without properties: an object with the key, any extras.
    ((required: ("a",)), ((b: 1),), ((a: 1, b: 2), "x", 1)),
    (deps, ((a: 1),), ((a: 1, b: 2), (c: 1), "x")),
    ((type: "array"), ("a",), ((1, "a", none), ())),
  ) {
    for v in bad { check(js, v, strict, false) }
    for v in good { check(js, v, strict, true) }
  }
}

// `{}` coerces any value unchanged, a strict-mode null too.
#assert.eq(coerce((a: (1, none), b: "x"), schema: any-type), (
  a: (1, none),
  b: "x",
))
#assert.eq(
  coerce((x: none), schema: object((x: any-type)), strict-null: true),
  (x: none),
)

// The errors stay the narrowed member's own.
#let short = validate("a", schema: T((minLength: 2)))
#assert.eq(short.map(e => (e.path, e.code)), (((), "length"),))
#assert.eq(short.at(0).message, "expected string length ≥ 2, got 1.")
#assert.eq(
  validate(0, schema: T((minimum: 1))).map(e => e.message),
  ("expected ≥ 1, got 0.",),
)
#assert.eq(validate("x", schema: T((format: "date"))).map(e => e.code), (
  "format",
))
