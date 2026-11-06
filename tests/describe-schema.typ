// describe-schema's exact output for one small schema that carries
// every feature it draws, so a format change shows up as a diff here.

#import "../lib.typ": (
  describe-schema, object, array-of, map, str-type, number-type, integer-type,
  email-string, date-string, datetime-string, pattern-string, enum-of, any-of,
  one-of, not-of,
)

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
code    pattern-string
email*  email-string
extra:
  *  str
jobs[]:
  start   date-string
  title*  str
name*   str (min-length 1, max-length 80)
other:
  not  number
phone   str
place   one of:
  [0]  str
  [1]:
    city  str
role    enum (\"ic\", \"manager\")
tags[]  str (min-items 1, unique-items)
when    any of:
  [0]  datetime-string
  [1]  date-string
phone → email",
)

// At the root: a union's header leads, a `not` member is labelled, and
// an array's constraints follow its element.
#assert.eq(
  describe-schema(any-of((str-type, array-of(number-type)))),
  "any of:\n  [0]    str\n  [1][]  number",
)
#assert.eq(describe-schema(not-of(object((a: str-type)))), "not:\n  a  str")
#assert.eq(
  describe-schema((kind: "array", elem: str-type, min-items: 2)),
  "[] str (min-items 2)",
)
#assert.eq(
  describe-schema(array-of(one-of((str-type, number-type)))),
  "[] one of:\n  [0]  str\n  [1]  number",
)
