// any-of, one-of and not-of (#108), and the unions the translator
// builds from a `type` array (#113) and from `[X, "null"]` (#84). A
// union validates against every member and models the value with the
// first that matches; `not` passes its value through as given.

#import "../lib.typ": (
  validate, coerce, parse, schema-from-json-schema, describe-schema, find-paths,
  schema-get, schema-put, markup, null, array-of, object, enum-of, any-of,
  one-of, not-of, if-of, nullable, string, boolean, number, integer,
)

#let T = schema-from-json-schema

// ---- any-of ------------------------------------------------------------

#let str-or-num = any-of((string(), number()))
#assert.eq(validate(str-or-num, "hi"), ())
#assert.eq(validate(str-or-num, 42), ())

// The members as separate arguments build the same node as the array
// form. A lone schema is one member, not an array to unpack.
#assert.eq(any-of(string(), number()), str-or-num)
#assert.eq(one-of(string(), number()), one-of((string(), number())))
#assert.eq(any-of(string()), any-of((string(),)))
#assert.eq(one-of(string()).members, (string(),))
#let obj = object((a: string()))
#assert.eq(any-of(obj), any-of((obj,)))
#assert.eq(any-of(obj, array-of(obj)).members, (obj, array-of(obj)))

#let no-match = validate(str-or-num, true)
#assert.eq(no-match.len(), 1)
#assert.eq(no-match.at(0).path, ())
#assert(no-match.at(0).message.contains("none matched"))
#assert(no-match.at(0).message.contains("string | number"))
// A nested union reads as its members, not as "union".
#assert.eq(
  validate(any-of(string(), one-of(number(), boolean())), (:)).first().message,
  "expected a value matching one of: string | (number | boolean); none matched.",
)

// A member claims a value when it has no `type` error at the union's
// own path, read from its schema, not its error text. When one member
// claims, its own error is reported instead of the summary.
#let letter-or-num = any-of((enum-of(("a", "b")), number()))
// The enum takes strings, not bools: no member claims `true`.
#let bool-err = validate(letter-or-num, true)
#assert.eq(bool-err.map(e => e.code), ("type",))
#assert(bool-err.at(0).message.contains("none matched"))
// A string is claimed by the enum alone.
#let letter-err = validate(letter-or-num, "c")
#assert.eq(letter-err.map(e => e.code), ("enum",))
#assert(letter-err.at(0).message.starts-with("expected one of \"a\", \"b\""))
// A number breaking a range is claimed by the number member.
#assert(
  validate(
    any-of((
      enum-of(("a", "b")),
      (..number(), minimum: 0),
    )),
    -1,
  )
    .at(0)
    .message
    .contains("≥ 0"),
)
// A float on an integer member is still claimed: `integer`, not `type`.
#let int-or-str = validate(
  any-of((
    integer(),
    string(pattern: "^a"),
  )),
  1.5,
)
#assert.eq(int-or-str.map(e => (e.path, e.code, e.expected, e.got)), (
  ((), "integer", none, 1.5),
))
// coerce models a claimed value as the claimant would alone: a
// constraint miss leaves the value, as it does outside a union.
#assert.eq(coerce(any-of(string(min-length: 5), number()), "x"), "x")
#assert.eq(
  coerce(any-of(object((a: markup())), string()), (a: "x", b: 1)),
  (a: [x]),
)
// A type error below the union's own path doesn't stop a member claiming.
#assert.eq(
  validate(any-of((object((a: string())), number())), (a: 1)).map(
    e => (e.path, e.code, e.expected, e.got),
  ),
  ((("a",), "type", "string", "integer"),),
)

// Inside an object, a union reports at its own path; null is absent.
#let holder = object((value: any-of((string(), array-of(number())))))
#assert.eq(validate(holder, (value: (1, 2))), ())
#assert.eq(validate(holder, (value: "text")), ())
#assert.eq(validate(holder, (value: true)).map(e => e.path), (
  ("value",),
))
#assert.eq(validate(holder, (value: none)), ())

// Nesting stays affordable: each level validates every member once.
// Twelve levels of a member that recurses through an array, failing at
// the bottom so every branch is walked.
#let deep = string()
#let deep-value = true
#for _ in range(12) {
  deep = any-of((deep, number(), array-of(deep)))
  deep-value = (deep-value,)
}
#assert.eq(validate(deep, deep-value).len(), 1)

// ---- one-of: exactly one -------------------------------------------------

#let exclusive = one-of((number(), enum-of((1, 2))))
// 3 matches only number().
#assert.eq(validate(exclusive, 3), ())
// 1 matches both.
#let multi = validate(exclusive, 1)
#assert.eq(multi.len(), 1)
#assert(multi.at(0).message.contains("exactly one"))
#assert(multi.at(0).message.contains("2 matched"))

// ---- not-of ------------------------------------------------------------

#let not-str = not-of(string())
#assert.eq(validate(not-str, 42), ())
#assert.eq(validate(not-str, (a: 1)), ())
#let negated = validate(not-str, "nope")
#assert.eq(negated.len(), 1)
#assert(negated.at(0).message.contains("not matching"))

// ---- if-of (#109) --------------------------------------------------------
//
// The condition's verdict picks the branch, and only the branch's
// errors are reported; a missing branch takes the value as it is.

#let x-word = string(pattern: "^x", expected: "starting with x")
#let long-x = if-of(string(min-length: 5), then: x-word)
#assert.eq(validate(long-x, "abc"), ())
#assert.eq(validate(long-x, "xyzzy"), ())
#assert.eq(validate(long-x, 42), ())
#assert.eq(validate(long-x, "abcde").map(e => e.message), (
  "expected starting with x.",
))
// Coerce follows the branch validate judged by.
#let rich-if-str = if-of(string(), then: markup(), otherwise: number())
#assert.eq(type(coerce(rich-if-str, "hi")), content)
#assert.eq(coerce(rich-if-str, 3), 3)
#assert.eq(validate(rich-if-str, true).map(e => e.code), ("type",))

// In a union, a conditional member claims a value as its chosen branch
// does: here a string, whose branch only breaks a constraint, so its
// own error is reported.
#let short-str = if-of(
  string(),
  then: string(min-length: 2),
  otherwise: number(),
)
#let bool-or-cond = any-of(boolean(), short-str)
#assert.eq(validate(bool-or-cond, true), ())
#assert.eq(validate(bool-or-cond, 1), ())
#assert.eq(validate(bool-or-cond, "a").map(e => e.code), ("length",))
// Neither branch takes an object: no member claims it. The `type`
// error's `expected` lists what each member's own type error does, so
// a conditional the branch its condition picked. The message names the
// member `conditional` when its branches differ...
#let unclaimed = validate(bool-or-cond, (a: 1))
#assert.eq(unclaimed.map(e => e.code), ("type",))
#assert.eq(unclaimed.at(0).expected, "boolean or number")
// A branch the condition didn't pick names nothing, even one with no
// type gate of its own.
#assert.eq(
  validate(
    any-of(
      boolean(),
      if-of(string(), then: not-of(number()), otherwise: number()),
    ),
    (a: 1),
  ).map(e => (e.code, e.expected)),
  (("type", "boolean or number"),),
)
#assert(unclaimed.at(0).message.contains("boolean | conditional"))
// ...and by its branches' kind when they agree.
#assert.eq(
  validate(
    any-of(
      boolean(),
      if-of(string(), then: string(min-length: 2), otherwise: x-word),
    ),
    1,
  )
    .at(0)
    .message,
  "expected a value matching one of: boolean | string; none matched.",
)
#assert(
  validate(not-of(short-str), "ab")
    .at(0)
    .message
    .contains("negated conditional schema"),
)
// A missing branch matches every value that takes it, so a one-of
// counts the conditional for a number here.
#let num-or-cond = one-of(number(), if-of(string(), then: x-word))
#assert.eq(validate(num-or-cond, "xy"), ())
#assert(
  validate(num-or-cond, 1).at(0).message.contains("2 matched"),
)

// ---- coerce --------------------------------------------------------------

// A union models the value with the first matching member: content
// wraps, the rest pass through, inside a document too.
#let rich-or-num = any-of((markup(), number()))
#assert.eq(type(coerce(rich-or-num, "hello")), content)
#assert.eq(coerce(rich-or-num, 7), 7)
#let doc-schema = object((x: any-of((string(), number()))))
#assert.eq(coerce(doc-schema, (x: 5)).x, 5)
#assert.eq(coerce(doc-schema, (x: "s")).x, "s")

// `not` has no shape to coerce toward: the value passes through.
#assert.eq(coerce(not-of(string()), 42), 42)
#assert.eq(coerce(not-of(string()), (a: 1)), (a: 1))

// ---- a `type` array ------------------------------------------------------
//
// One member per type, a null member last; duplicates build one member.

#let su = T((type: ("string", "number")))
#assert.eq(su, any-of((string(), number())))
#assert.eq(T((type: ("string", "string"))), string())
#let with-null = T((type: ("string", "number", "null")))
#assert.eq(with-null, any-of((string(), number(), null())))
#assert.eq(T((type: ("null", "null"))), T((type: "null")))

#let v(s) = T((type: "object", properties: (v: s)))
#let either = v((type: ("string", "number")))
#for ok in ("a", 3, 1.5, none) {
  assert.eq(validate(either, (v: ok)), ())
}
#assert.eq(validate(either, (v: true)).len(), 1)
// A wrong-typed value gets the summary.
#assert(
  validate(either, (v: true))
    .at(0)
    .message
    .contains(
      "none matched",
    ),
)
// The null member judges no non-null value: by default the union
// reports what the types alone would.
#assert.eq(validate(with-null, true), validate(su, true))
// A null member is known by its kind, so an annotated one stays out
// of the way too, and still draws as `X?`.
#let noted-null = any-of(string(), (..null(), description: "unset"))
#assert.eq(validate(noted-null, 5), validate(string(), 5))
#assert.eq(describe-schema(object((a: noted-null))), "a  string?")

// Each type's keywords apply to its own member only.
#let constrained = v((type: ("string", "integer"), minLength: 3, minimum: 10))
#for ok in ("abc", 10, 100, "a-long-string") {
  assert.eq(validate(constrained, (v: ok)), ())
}
#assert(validate(constrained, (v: 9)).len() > 0)
// A right-typed value that breaks a constraint reports the constraint.
#let short = validate(constrained, (v: "ab"))
#assert.eq(short.len(), 1)
#assert(short.at(0).message.contains("string length"))

// Containers as members.
#let mixed = v((type: ("string", "array"), items: (type: "integer")))
#assert.eq(validate(mixed, (v: "x")), ())
#assert.eq(validate(mixed, (v: (1, 2))), ())
#assert(validate(mixed, (v: ("x",))).len() > 0)

// Overlapping members stay valid (any-of, not one-of).
#assert.eq(validate(v((type: ("number", "integer"))), (v: 1)), ())

// ---- nullable ------------------------------------------------------------
//
// `nullable(X)` is any-of((X, null())), and `type: [X, "null"]`
// translates to it. By default it validates and coerces exactly as X
// does; with strict-null it accepts the null that plain X rejects.

#assert.eq(nullable(string()), any-of((string(), null())))

// Each case: the nullable JSON Schema, the same without "null", and
// values to judge.
#for (nullable-js, plain-js, values) in (
  (
    (type: ("string", "null"), minLength: 2),
    (type: "string", minLength: 2),
    ("ab", "a", 1, true),
  ),
  (
    (
      type: ("object", "null"),
      properties: (a: (type: "string"), b: (type: "integer")),
      required: ("a",),
      dependentRequired: (b: ("a",)),
    ),
    (
      type: "object",
      properties: (a: (type: "string"), b: (type: "integer")),
      required: ("a",),
      dependentRequired: (b: ("a",)),
    ),
    ((a: "x"), (b: 1), (a: 1), (c: 1), (a: none, b: 2), "x"),
  ),
  (
    (type: ("array", "null"), items: (type: "string"), minItems: 2),
    (type: "array", items: (type: "string"), minItems: 2),
    (("a", "b"), ("a",), ("a", none, "b"), ("a", 1), "x"),
  ),
) {
  let n = T(nullable-js)
  let p = T(plain-js)
  assert.eq(n, nullable(p))
  let wrap(s) = T((type: "object", properties: (f: s), required: ("f",)))
  for x in values {
    // Bare, inside an object, and as an array element.
    assert.eq(validate(n, x), validate(p, x))
    assert.eq(
      validate(wrap(nullable-js), (f: x)),
      validate(wrap(plain-js), (f: x)),
    )
    if validate(p, x).all(e => (
      e.code not in ("type", "enum", "union")
    )) {
      assert.eq(coerce(n, x), coerce(p, x))
      assert.eq(
        coerce((kind: "array", elem: n), (x, none)),
        coerce((kind: "array", elem: p), (x, none)),
      )
    }
  }
  // Null: absent by default, so required still fires and the model
  // drops it.
  let (wn, wp) = (wrap(nullable-js), wrap(plain-js))
  assert.eq(validate(wn, (f: none)), validate(wp, (f: none)))
  assert.eq(coerce(wn, (f: none)), coerce(wp, (f: none)))
  // Strict: the nullable field accepts it and keeps it; plain X rejects it.
  assert.eq(validate(wn, (f: none), strict-null: true), ())
  assert.eq(parse(wn, (f: none), strict-null: true), (f: none))
  assert.eq(
    validate(wp, (f: none), strict-null: true).map(e => e.code),
    ("type",),
  )
}

// Several types plus "null": by default the same as the types alone.
#let multi = T((type: ("string", "integer", "null")))
#for x in ("a", 1, 1.5, true, (a: 1)) {
  assert.eq(
    validate(multi, x),
    validate(T((type: ("string", "integer"))), x),
  )
}
#assert.eq(
  validate(
    v((type: ("string", "integer", "null"))),
    (v: none),
    strict-null: true,
  ),
  (),
)

// Schema paths and find-paths reach X as member 0.
#let doc = T((
  type: "object",
  properties: (
    when: (type: ("string", "null"), format: "date"),
    name: (type: ("string", "null")),
  ),
))
#assert.eq(find-paths(doc, string(format: "date")), (("when", 0),))
#assert.eq(schema-get(doc, ("when",)).kind, "union")
#assert.eq(schema-get(doc, ("when", 0)).kind, "string")
#assert.eq(schema-get(doc, ("when", 0)).format, "date")
#assert.eq(schema-get(doc, ("name", 0)), string())
#assert.eq(
  schema-put(doc, ("name", 0), (..string(), min-length: 1)).shape.name,
  nullable((..string(), min-length: 1)),
)
#assert.eq(describe-schema(doc), "name  string?\nwhen  string (date)?")

// allOf over nullable objects merges the objects; the merge is nullable
// only when every member is.
#let obj(p) = (type: ("object", "null"), properties: p)
#let ab = T((
  type: "object",
  properties: (a: (type: "string"), b: (type: "string")),
))
#assert.eq(
  T((allOf: (obj((a: (type: "string"))), obj((b: (type: "string")))))),
  nullable(ab),
)
#assert.eq(
  T((
    allOf: (
      obj((a: (type: "string"))),
      (type: "object", properties: (b: (type: "string"))),
    ),
  )),
  ab,
)
