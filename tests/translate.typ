// schema-from-json-schema: each JSON Schema (draft 7 subset) construct
// and the node it builds. The canonical JSON Resume document is
// covered in tests/resume-schema.typ, and what the translator rejects
// in tests/panics/.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, boolean, null, unknown, array-of,
  object, enum-of, const-of, any-of, one-of, not-of, if-of, nullable, number,
  string, describe-schema, integer,
)

#let T = schema-from-json-schema
#let x-gate = (pattern: regex("^x$"), expected: "matching " + repr("^x$"))

// ---- one node per construct ----------------------------------------------

#for (js, node) in (
  // Types. `integer` keeps its integral gate rather than flattening to
  // number, which would silently drop the constraint.
  ((type: "string"), string()),
  ((type: "number"), number()),
  ((type: "integer"), integer()),
  ((type: "boolean"), boolean()),
  ((type: "null"), null()),
  ((type: "array", items: (type: "string")), array-of(string())),
  (
    (type: "array", items: (type: "array", items: (type: "number"))),
    array-of(array-of(number())),
  ),
  // A pattern is a patterned string with a hint naming it (regexes compare
  // by source). With a format, the formatted string carries it as an
  // extra gate.
  (
    (type: "string", pattern: "^[A-Z]{2}$"),
    string(pattern: "^[A-Z]{2}$", expected: "matching " + repr("^[A-Z]{2}$")),
  ),
  (
    (type: "string", format: "email", pattern: "^x$"),
    string(format: "email") + x-gate,
  ),
  (
    (type: "string", format: "uri", pattern: "^x$"),
    string(format: "uri") + x-gate,
  ),
  (
    (type: "string", format: "date", pattern: "^x$"),
    string(format: "date") + x-gate,
  ),
  (
    (type: "string", format: "date-time", pattern: "^x$"),
    string(format: "date-time") + x-gate,
  ),
  // `[X, "null"]` is nullable(X), whichever comes first; X keeps its
  // own keywords. A repeated type is one.
  ((type: ("string", "null")), nullable(string())),
  ((type: ("null", "integer")), nullable(integer())),
  (
    (type: ("string", "null"), format: "email"),
    nullable(string(format: "email")),
  ),
  ((type: ("string", "string", "null")), nullable(string())),
  // A `type` array builds each member from the whole node, each ignoring
  // the other types' keywords, as in draft 7.
  (
    (type: ("string", "number"), minimum: 1),
    any-of((string(), number(minimum: 1))),
  ),
  // enum maps to enum-of whatever the `type`, values verbatim; const to
  // const-of, the singleton enum.
  ((enum: ("a", "b", "c")), enum-of(("a", "b", "c"))),
  ((type: "string", enum: ("a", "b")), enum-of(("a", "b"))),
  ((enum: (1, "two", 3.0)), enum-of((1, "two", 3.0))),
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
    string(),
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
  // With both, a value must be in the enum and equal the const.
  ((enum: (1, 2), const: 2), const-of(2)),
  // anyOf / oneOf / not, nested too.
  (
    (anyOf: ((type: "string"), (type: "number"))),
    any-of((string(), number())),
  ),
  (
    (oneOf: ((type: "string"), (type: "boolean"))),
    one-of((string(), boolean())),
  ),
  (("not": (type: "string")), not-of(string())),
  // `not` is only a test, like `if`: every object in it with no
  // `additionalProperties` is open, as draft 7 reads it.
  (
    ("not": (type: "object", properties: (a: (type: "object")))),
    not-of(object((a: object((:), additional: true)), additional: true)),
  ),
  // if / then / else with no siblings: the branches as written, of any
  // kind; `if` with neither branch is dropped (draft 7 checks nothing).
  (
    (
      "if": (type: "string", minLength: 5),
      then: (type: "string", pattern: "^x$"),
      "else": (type: "number"),
    ),
    if-of(string(min-length: 5), then: string(..x-gate), otherwise: number()),
  ),
  (
    ("if": (type: "string"), "else": (type: "number")),
    if-of(
      string(),
      otherwise: number(),
    ),
  ),
  (("if": (type: "string")), unknown()),
  ((type: "string", minLength: 2, "if": (minLength: 5)), string(min-length: 2)),
  (
    (anyOf: ((type: "string"), (oneOf: ((type: "number"), (type: "boolean"))))),
    any-of((string(), one-of((number(), boolean())))),
  ),
  // No `type`: `{}` and annotations alone take any value; a keyword
  // narrows only its own type's member.
  ((:), unknown()),
  ((title: "x", description: "anything"), unknown()),
  ((type: "array"), array-of(unknown())),
  ((type: "array", minItems: 1), (..array-of(unknown()), min-items: 1)),
  (
    (minLength: 2),
    any-of((
      boolean(),
      object((:), additional: true),
      array-of(unknown()),
      number(),
      (..string(), min-length: 2),
      null(),
    )),
  ),
  // Every entry form: a dict, or bytes as Typst's decoders take.
  (bytes("{\"type\": \"string\"}"), string()),
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
  (name: string(), age: integer()),
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
  unknown(),
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
  startDate: string(),
  viaAlias: string(),
  summary: string(),
))
#assert.eq(
  T((
    "$defs": (item: (type: "string")),
    type: "array",
    items: ("$ref": "#/$defs/item"),
  )),
  array-of(string()),
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
  slash: string(),
  tilde: number(),
  indexed: integer(),
  utf8: string(),
  percent: string(),
  quote: number(),
  tilde-space: boolean(),
  plain: integer(),
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
    string(),
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
    object((name: string(), age: integer()), required-keys: ("name", "age")),
  ),
  ((obj((a: (type: "string"))),), (:), object((a: string()))),
  (
    (
      obj((a: (type: "string"))),
      obj((a: (type: "string"), b: (type: "number"))),
    ),
    (:),
    object((a: string(), b: number())),
  ),
  (
    (("$ref": "#/definitions/base"), obj((extra: (type: "number")))),
    (definitions: (base: obj((id: (type: "string"))))),
    object((id: string(), extra: number())),
  ),
  (
    (obj((a: (type: "string"))),),
    (title: "combined", description: "docs only"),
    object((a: string())),
  ),
  // additionalProperties must agree across every member (an undeclared
  // one counts as closed): open members merge open.
  (
    (
      obj((a: (type: "string")), additionalProperties: true),
      obj((b: (type: "number")), additionalProperties: true),
    ),
    (:),
    object((a: string(), b: number()), additional: true),
  ),
  // Closed or typed members merge when they declare the same
  // properties, so each one's additionalProperties sees the same extras.
  (
    (
      obj((a: (type: "string")), additionalProperties: false),
      obj((a: (type: "string")), required: ("a",), additionalProperties: false),
    ),
    (:),
    object((a: string()), required-keys: ("a",)),
  ),
  (
    (
      obj((a: (type: "string")), additionalProperties: (type: "number")),
      obj((a: (type: "string")), additionalProperties: (type: "number")),
    ),
    (:),
    object((a: string()), additional: number()),
  ),
  // `additionalProperties: {}` takes any value, so it is `true`.
  (
    (
      obj((a: (type: "string")), additionalProperties: (:)),
      obj((b: (type: "number")), additionalProperties: true),
    ),
    (:),
    object((a: string(), b: number()), additional: true),
  ),
) {
  assert.eq(T((allOf: members, ..extra)), node, message: repr(members))
}

// ---- a node without `type` -------------------------------------------------
//
// Draft 7: `{}` takes any value, and a type-specific keyword constrains
// only values of its own type. Adapted from the JSON Schema test suite.

#assert.eq(describe-schema(unknown()), "unknown")

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
  let errs = validate(object((x: T(js))), (x: value), strict-null: strict)
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
#assert.eq(coerce(unknown(), (a: (1, none), b: "x")), (
  a: (1, none),
  b: "x",
))
#assert.eq(
  coerce(object((x: unknown())), (x: none), strict-null: true),
  (x: none),
)

// The errors stay the narrowed member's own.
#let short = validate(T((minLength: 2)), "a")
#assert.eq(short.map(e => (e.path, e.code)), (((), "length"),))
#assert.eq(short.at(0).message, "expected string length ≥ 2, got 1.")
#assert.eq(
  validate(T((minimum: 1)), 0).map(e => e.message),
  ("expected ≥ 1, got 0.",),
)
#assert.eq(validate(T((format: "date")), "x").map(e => e.code), (
  "format",
))

// ---- if / then / else (#109) -----------------------------------------------
//
// `{A…, if: I, then: T, else: E}` is if-of(I, then: allOf(A, T),
// otherwise: allOf(A, E)), so the siblings apply whichever branch the
// value takes. With no siblings the branches are T and E as written.

#let codes(errs) = errs.map(e => (e.path, e.code))

// A lone if / then on strings. A missing `else` takes the value as it
// is, and an untyped keyword passes other types, as in draft 7.
#let long-x = T(("if": (minLength: 5), then: (pattern: "^x")))
#assert.eq(long-x, if-of(T((minLength: 5)), then: T((pattern: "^x"))))
#for v in ("abc", "xyzzy", 42, (a: 1)) {
  assert.eq(validate(long-x, v), (), message: repr(v))
  assert.eq(coerce(long-x, v), v)
}
#assert.eq(codes(validate(long-x, "abcde")), (((), "pattern"),))
// A missing `then`.
#let not-string = T(("if": (type: "string"), "else": (type: "number")))
#assert.eq(validate(not-string, "a"), ())
#assert.eq(validate(not-string, 1), ())
#assert.eq(codes(validate(not-string, true)), (((), "type"),))

// The classic example, from the JSON Schema guide: the postal code's
// pattern depends on the country.
#let us-zip = "^[0-9]{5}(-[0-9]{4})?$"
#let ca-post = "^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$"
#let address = T((
  type: "object",
  properties: (country: (type: "string")),
  "if": (properties: (country: (const: "US"))),
  then: (properties: (postal_code: (pattern: us-zip))),
  "else": (properties: (postal_code: (pattern: ca-post))),
))
#assert.eq(
  address,
  if-of(
    // The condition is only a test: its object is open, so it holds
    // for an address with more keys than `country`.
    T((properties: (country: (const: "US")), additionalProperties: true)),
    then: T((
      type: "object",
      properties: (country: (type: "string"), postal_code: (pattern: us-zip)),
    )),
    otherwise: T((
      type: "object",
      properties: (country: (type: "string"), postal_code: (pattern: ca-post)),
    )),
  ),
)
#for (value, errors) in (
  ((country: "US", postal_code: "12345"), ()),
  ((country: "CA", postal_code: "K1A 0B1"), ()),
  ((country: "US", postal_code: "K1A 0B1"), ((("postal_code",), "pattern"),)),
  ((country: "CA", postal_code: "12345"), ((("postal_code",), "pattern"),)),
  // No country: `properties` holds, as in draft 7, so the US branch.
  ((postal_code: "K1A 0B1"), ((("postal_code",), "pattern"),)),
  // The siblings apply in both branches: `country` is a string, and
  // the object is closed.
  ((country: 1, postal_code: "K1A 0B1"), ((("country",), "type"),)),
  (
    (country: "US", postal_code: "12345", street: "x"),
    (
      (("street",), "unknown-key"),
    ),
  ),
) {
  assert.eq(
    codes(validate(address, value)),
    errors,
    message: repr(
      value,
    ),
  )
}
#assert.eq(
  validate(address, (country: "CA", postal_code: "12345")).at(0).expected,
  "matching " + repr(ca-post),
)
// Every object in the condition is open, nested ones and `type:
// "object"` with no properties too; a declared additionalProperties
// is kept.
#assert.eq(
  T((
    "if": (
      type: "object",
      properties: (
        a: (type: "object", properties: (b: (const: 1))),
        c: (type: "object"),
        d: (type: "object", properties: (:), additionalProperties: false),
      ),
    ),
    then: (type: "string"),
  )).cond,
  object(
    (
      a: object((b: const-of(1)), additional: true),
      c: object((:), additional: true),
      d: object((:)),
    ),
    additional: true,
  ),
)
// A branch that is a `$ref` merges as its target.
#assert.eq(
  T((
    definitions: (
      us: (
        type: "object",
        properties: (country: (type: "string"), postal_code: (pattern: us-zip)),
      ),
    ),
    type: "object",
    properties: (country: (type: "string")),
    "if": (properties: (country: (const: "US"))),
    then: ("$ref": "#/definitions/us"),
    "else": (properties: (postal_code: (pattern: ca-post))),
  )),
  address,
)
// Coerce follows the branch: the undeclared key is dropped.
#assert.eq(
  coerce(address, (country: "CA", postal_code: "K1A 0B1", street: "x")),
  (country: "CA", postal_code: "K1A 0B1"),
)

// A branch reads its siblings' `type`, `properties` and
// `additionalProperties` when it doesn't set them, so `then:
// {required: […]}` requires a sibling property. A missing branch is
// the siblings alone.
#let kinded = T((
  type: "object",
  properties: (kind: (type: "string"), extra: (type: "string")),
  "if": (properties: (kind: (const: "x")), required: ("kind",)),
  then: (required: ("extra",)),
))
#assert.eq(
  kinded.then,
  object((kind: string(), extra: string()), required-keys: ("extra",)),
)
#assert.eq(kinded.otherwise, object((kind: string(), extra: string())))
#assert.eq(codes(validate(kinded, (kind: "x"))), (
  (("extra",), "required"),
))
#assert.eq(validate(kinded, (kind: "x", extra: "e")), ())
#assert.eq(validate(kinded, (kind: "y")), ())
#assert.eq(
  T((
    type: "object",
    properties: (a: (type: "string")),
    additionalProperties: true,
    "if": (required: ("a",)),
    then: (properties: (b: (type: "number"))),
  )).then,
  object((a: string(), b: number()), additional: true),
)
// Siblings that are only `type: "object"` add nothing to a branch, so
// a closed branch stands alone rather than merging with an open object.
#let closed-ab(p) = (
  properties: ((p): (type: "string")),
  additionalProperties: false,
)
#assert.eq(
  T((
    type: "object",
    description: "a or b",
    "if": (required: ("a",)),
    then: closed-ab("a"),
    "else": closed-ab("b"),
  )),
  if-of(
    T((required: ("a",), additionalProperties: true)),
    then: object((a: string())),
    otherwise: object((b: string())),
  ),
)

// `not` reads its objects open, as draft 7 does: an object with more
// keys than the ones it names still matches, so `not` rejects it.
#let not-legacy = T((
  "not": (
    type: "object",
    properties: (kind: (const: "legacy")),
    required: ("kind",),
  ),
))
#assert.eq(codes(validate(not-legacy, (kind: "legacy", id: 7))), (
  ((), "not"),
))
#assert.eq(validate(not-legacy, (kind: "current", id: 7)), ())

// Nesting: the translator's recursion spends as few call frames per level
// as the walk does, so a schema it translates is one validate can walk.
// REFERENCE.md states these depths; a lost frame per level fails here.
#let nested(n, wrap) = range(n).fold((type: "string"), (j, _) => wrap(j))
#let deep-props = T(nested(30, j => (type: "object", properties: (a: j))))
#assert.eq(validate(deep-props, range(30).fold("x", (d, _) => (a: d))), ())
#let deep-any = T(nested(15, j => (
  anyOf: ((type: "object", properties: (a: j)), (type: "null")),
)))
#assert.eq(deep-any.kind, "union")
// An `allOf` or an `if` with siblings costs what an `anyOf` does, a
// lone `if` what `properties` does, and a `$ref` nothing.
#let deep-all-of = T(nested(15, j => (
  allOf: ((type: "object", properties: (a: j)),),
)))
#assert.eq(deep-all-of.kind, "object")
#let deep-if = T(nested(15, j => (
  type: "object",
  properties: (a: (type: "string")),
  "if": (required: ("a",)),
  then: (properties: (b: j)),
)))
#assert.eq(deep-if.kind, "if")
#assert.eq(T(nested(30, j => ("if": (minLength: 1), then: j))).kind, "if")
#let chain(n) = range(n).fold(
  (definitions: (d0: (type: "string"))),
  (js, i) => (
    definitions: (
      ..js.definitions,
      ("d" + str(i + 1)): (
        type: "object",
        properties: (a: ("$ref": "#/definitions/d" + str(i))),
      ),
    ),
    "$ref": "#/definitions/d" + str(i + 1),
  ),
)
#assert.eq(T(chain(30)).kind, "object")

// An enum value is literal JSON: a null item in an array value counts
// toward its length, whatever mode the data is validated in.
#assert.eq(
  validate(T((minItems: 2, enum: ((1, none), (1, 2)))), (1, none)),
  (),
)
#assert.eq(
  validate(T((maxItems: 1, enum: ((none, none), (1,)))), (none, none)).len(),
  1,
)

// allOf reads a nullable written null first as a nullable, and an
// additionalProperties that is a $ref to `{}` as open.
#assert.eq(
  T((
    allOf: (
      (anyOf: ((type: "null"), (type: "object", properties: (a: (:))))),
    ),
  )),
  nullable(object((a: unknown()))),
)
#assert.eq(
  validate(
    T((
      "$defs": (any: (:)),
      allOf: (
        (
          type: "object",
          properties: (a: (:)),
          additionalProperties: ("$ref": "#/$defs/any"),
        ),
        (type: "object", properties: (b: (:)), additionalProperties: true),
      ),
    )),
    (a: 1, b: 2),
  ),
  (),
)
