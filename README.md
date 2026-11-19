<h1 align="center">gairm-import</h1>

<p align="center">
  <a href="https://typst.app/universe/package/gairm-import"><img alt="gairm-import on Typst Universe" src="https://img.shields.io/badge/Typst_Universe-gairm--import-239DAE?logo=typst&style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/releases"><img alt="Latest GitHub release version of gairm-import" src="https://img.shields.io/github/v/release/smur89/gairm-import?style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/actions/workflows/build.yml"><img alt="GitHub Actions build workflow status on the gairm-import main branch" src="https://img.shields.io/github/actions/workflow/status/smur89/gairm-import/build.yml?style=flat-square"></a>
  <a href="LICENSE"><img alt="MIT license badge linking to the gairm-import LICENSE file" src="https://img.shields.io/github/license/smur89/gairm-import?style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/stargazers"><img alt="Number of GitHub stargazers for gairm-import" src="https://img.shields.io/github/stars/smur89/gairm-import?style=flat-square"></a>
</p>

<p align="center">
  <strong>Validate JSON against a schema, get typed Typst values.</strong>
  <br>
  Check a JSON document against a JSON Schema (draft&nbsp;7 subset) or a
  schema built in Typst, see every problem at once, and get back a
  normalised Typst value ready to render. Bring your own schema, such as
  <a href="https://jsonresume.org/schema">JSON Resume</a>'s.
</p>

<p align="center">
  <sub><em>"gairm" is Irish for vocation. The package was originally a JSON Resume loader.</em></sub>
</p>

## Contents

- [What it is](#what-it-is)
- [Quick start](#quick-start)
- [API at a glance](#api-at-a-glance)
- [Input forms](#input-forms)
- [Errors](#errors)
- [Null handling](#null-handling)
- [Validating a JSON Resume](#validating-a-json-resume)
- [Upgrading from 0.x](#upgrading-from-0x)
- [Reference](#reference)
- [Contributing](#contributing)
- [License](#license)

## What it is

gairm-import checks a JSON document against a schema and returns it as
Typst values. Every problem in the document is reported at once, each with
its path and, for a misspelt key, a "Did you mean …?" hint. The schema can
be a JSON Schema document or one you build with Typst functions, and you
can edit either through schema paths before use. Requires Typst `0.15.0`
or later.

## Quick start

Translate a JSON Schema document you already have:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": parse, schema-from-json-schema

#let book-schema = schema-from-json-schema(json("book-schema.json"))
#let book = parse(book-schema, path("book.json"))
```
<!-- x-release-please-end -->

`book-schema.json` is any JSON Schema document; this one says what the
Typst schema below says. Or build the schema in Typst:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": (
  parse, object, array-of, string, number,
)

#let book-schema = object(
  (
    title:  string(),
    author: string(),
    year:   number(),
    tags:   array-of(string()),
  ),
  required-keys: ("title", "author", "year", "tags"),
)

#let book = parse(book-schema, path("book.json"))
```
<!-- x-release-please-end -->

The translator takes a draft 7 subset and panics on anything it cannot
honour rather than dropping it; [REFERENCE.md](REFERENCE.md#json-schema-translation)
lists the keywords it supports and how it differs from draft 7.

With this `book.json`:

```json
{
  "title": "The Pocket Atlas of Imaginary Places",
  "author": "Aoife Brennan",
  "year": 1998,
  "tags": ["atlas", "fiction"]
}
```

the result mirrors the document: `book.title` is a string, `book.year` a
number and `book.tags` an array of strings.

## API at a glance

| Group | Names |
|---|---|
| Run | `parse`, `validate`, `coerce`, `format-errors` |
| Schemas | `schema-from-json-schema` |
| Constructors | `string`, `number`, `integer`, `boolean`, `null`, `markup`, `unknown`, `array-of`, `object`, `map`, `any-of`, `one-of`, `not-of`, `if-of`, `nullable`, `enum-of`, `const-of` |
| Edits | `schema-get`, `schema-put`, `schema-update`, `add-field`, `remove-field`, `set-required`, `unset-required` |
| Inspect | `describe-schema`, `find-paths` |
| Pointers | `path-to-pointer`, `pointer-to-path` |

`parse` validates and coerces in one call and panics with every problem
found. `validate` returns the problems as a list, and `coerce` builds the
model without checking. All three take the schema, then the data, and
`strict-null:` (default `false`). With the schema first, `.with` makes a
parser for one schema:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": parse, schema-from-json-schema

#let parse-book = parse.with(schema-from-json-schema(json("book-schema.json")))
#let book = parse-book(path("book.json"))
```
<!-- x-release-please-end -->

[REFERENCE.md](REFERENCE.md) covers the rest, one section per group.

## Input forms

`parse`, `validate` and `coerce` take the document, or where to read it:

| You pass | It is read as |
|---|---|
| `path("book.json")` | JSON, resolved from your file |
| bytes, such as `read("book.json", encoding: none)` | JSON |
| a dictionary, such as `json("book.json")` | the document itself |
| any other value: an array, a number, a string | the document itself, whatever root the schema takes |

A string is data, not a path: inside a package it would resolve from the
package, never your file, so a `.json`-looking string the schema rejects
panics with a hint to use `path(..)`. A `null` document panics.
`schema-from-json-schema` takes the first three forms only.

## Errors

`parse` reports every problem in one panic. The book from
[Quick start](#quick-start), whose schemas require all four fields, with
a numeric author, a misspelt `year` and a number among its tags:

```json
{
  "title": "The Pocket Atlas of Imaginary Places",
  "author": 1998,
  "yaer": 1998,
  "tags": ["atlas", 3]
}
```

```text
error: panicked with: gairm-import: found 4 problems in the input:
  - author: expected string, got integer.
  - yaer: unknown key "yaer". Did you mean "year"?
  - tags[1]: expected string, got integer.
  - year: missing required key "year".
```

To present problems yourself, call `validate`, which returns them as
records. The first line above is `(path: ("author",), code: "type",
message: "expected string, got integer.", expected: "string", got:
"integer")`. A record's `path` is where in the document the problem is;
for a missing key, `required` or `dependent`, it is the key that is
missing.

Branch on `code`, not on the message;
[REFERENCE.md](REFERENCE.md#error-records) lists every code and what
`expected` and `got` hold for each.

`format-errors(errors)` turns the records into `parse`'s report, reading
only `path` and `message`:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": (
  validate, coerce, format-errors, schema-from-json-schema,
)

#let book-schema = schema-from-json-schema(json("book-schema.json"))
#let doc = json("book.json")
#let errors = validate(book-schema, doc)
#if errors.len() > 0 {
  [Book has #errors.len() issue(s).]
  raw(format-errors(errors))
} else {
  let book = coerce(book-schema, doc)
  // render book …
}
```
<!-- x-release-please-end -->

## Null handling

By default JSON `null` means "absent", as most JSON emitters intend
(`"summary": null` is the same as no summary). Pass `strict-null: true` to
`parse`, `validate` or `coerce` when `null` must mean something: it is then
an ordinary value that a schema accepts or rejects.

| Input | Default | `strict-null: true` |
|---|---|---|
| required key missing | `required` | `required` |
| key holding `null`, field not nullable | `required` if required, else dropped from the model | `type`, "got null" |
| key holding `null`, field `nullable(X)` | dropped | accepted, kept as `none` |
| unknown key holding `null` | `unknown-key` | `unknown-key` |
| `null` array element | dropped | `type`, or kept if the element is `nullable(X)` (and counted by `min-items` / `unique-items`) |
| dependent-required trigger holding `null` | does not fire | fires |
| object whose keys are all `null` | kept as `(:)` | judged key by key |
| free-form object (no fields, `additional: true`) | passed through as given, nulls and all | the same |
| the whole document is `null` | panics | panics |

`nullable(X)` accepts `null` or whatever `X` accepts, and judges a non-null
value exactly as `X` does:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": parse, object, string, nullable

#let schema = object(
  (name: string(), nickname: nullable(string())),
  required-keys: ("name", "nickname"),
)
#parse(schema, (name: "Ada", nickname: none), strict-null: true)
// → (name: "Ada", nickname: none)
```
<!-- x-release-please-end -->

## Validating a JSON Resume

[JSON Resume](https://jsonresume.org/schema) publishes its schema as a JSON
Schema document. Save a copy beside your file as `resume.schema.json`,
from [jsonresume.org/schema](https://jsonresume.org/schema) or the
[`@jsonresume/schema`](https://www.npmjs.com/package/@jsonresume/schema)
npm package, and translate it:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": parse, schema-from-json-schema

#let resume-schema = schema-from-json-schema(json("resume.schema.json"))
#let resume = parse(resume-schema, path("resume.json"))
// hand `resume` to any compatible Typst CV template
```
<!-- x-release-please-end -->

A minimal `resume.json`:

```json
{
  "basics": {
    "name": "Seán Ó Murchú",
    "label": "Senior Software Engineer",
    "email": "sean@example.com",
    "summary": "Backend engineer with eight years of experience."
  },
  "work": [
    {
      "name": "Acme Corp",
      "position": "Senior Software Engineer",
      "startDate": "2022-01",
      "highlights": ["Led the event-sourcing platform migration."]
    }
  ]
}
```

The result mirrors the document: `resume.basics.name` and
`resume.work.at(0).position` are strings, `resume.work.at(0).highlights` an
array of strings. Your copy of the schema decides the version, so a field
upstream adds works as soon as you update the file. Pass the result to any
renderer that takes JSON Resume data, such as
[`altacv`](https://typst.app/universe/package/altacv):

<!-- Two fences (not one): a single fence would let release-please rewrite this altacv pin on every gairm release. Bump it by hand when altacv publishes a new version. See https://github.com/typst/packages/pull/5069#discussion_r3420827761 -->

```typst
#import "@preview/altacv:1.9.0": alta
```

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": parse, schema-from-json-schema

#let resume-schema = schema-from-json-schema(json("resume.schema.json"))
#alta(parse(resume-schema, path("resume.json")))
```
<!-- x-release-please-end -->

The schema declares no nullable fields, so with `strict-null: true` it
rejects a `null` in any declared field. The free-form `custom` objects
check nothing, so a `null` there is kept.

Upstream sets `additionalProperties: true` at the top level and on every
section's items, so undeclared keys pass: a misspelt `positon` is kept
rather than reported. Its date fields (`startDate`, `endDate`, `date`, …)
are strings checked by its `iso8601` regex. For a stricter schema, edit
the document before translating it and the schema after:

- close every object that declares properties, so an undeclared key is an
  error. Typed extras (`additionalProperties` with a schema) still pass if
  they match, and the free-form `custom` objects, which declare none, stay
  open;
- check the date fields as a full date with `format: "date"`, which also
  takes a Typst `datetime`, or as the year or year and month JSON Resume
  allows;
- make the free-text fields Typst `content`, so they splice into markup.

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.13.0": (
  parse, schema-from-json-schema, schema-put, markup,
)

// Not for schemas with `not` or `if`: closing an object there loosens them.
#let close(js) = if type(js) == dictionary {
  let js = js.pairs().map(((k, v)) => (k, close(v))).to-dict()
  if (
    "properties" in js and js.at("additionalProperties", default: true) == true
  ) {
    js.additionalProperties = false
  }
  js
} else if type(js) == array { js.map(close) } else { js }

#let strict-json = {
  let js = close(json("resume.schema.json"))
  // A full date, or the year and month JSON Resume also allows.
  js.definitions.iso8601 = (
    anyOf: (
      (type: "string", format: "date"),
      (type: "string", pattern: "^[0-9]{4}(-(0[1-9]|1[0-2]))?$"),
    ),
  )
  js
}

#let resume-schema-strict = (
  ("objective",),
  ("basics", "summary"),
  ("work", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("volunteer", "items", "highlights", "items"),
  ("education", "items", "summary"),
  ("awards", "items", "summary"),
  ("certificates", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("projects", "items", "summary"),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
).fold(
  schema-from-json-schema(strict-json),
  (schema, at) => schema-put(schema, at, markup()),
)

#let resume = parse(resume-schema-strict, path("resume.json"))
```
<!-- x-release-please-end -->

Under the strict schema, a misspelt key in a work entry is reported with
a suggestion:

```text
  - work[0].positon: unknown key "positon". Did you mean "position"?
```

For a different mix, or for a renderer's own fields, edit either schema;
see [REFERENCE.md](REFERENCE.md#schema-paths-and-edits).

## Upgrading from 0.x

| 0.x | 1.0 |
|---|---|
| `parse(data, schema: s)`, and `validate`, `coerce` | `parse(s, data)`: the schema first |
| `resume-schema`, `resume-schema-strict` | your own copy, translated: [Validating a JSON Resume](#validating-a-json-resume) |
| `str-type`, `number-type`, `integer-type` | `string()`, `number()`, `integer()` |
| `bool-type`, `null-type`, `any-type`, `content-type` | `boolean()`, `null()`, `unknown()`, `markup()` |
| `date-string`, `uri-string`, … | `string(format: "date")`, `string(format: "uri")`, … |
| `pattern-string(re)` | `string(pattern: re)` |
| `paths-of-kind` | `find-paths` |
| `lens(p)`, `(lens: p)`, `lens-then(a, b)` | the path `p`, `a + b` |
| `kind-at(s, at)` | `schema-get(s, at).kind` |
| `lens-get(at, s)`, `lens-put`, `lens-over` | `schema-get(s, at)`, `schema-put`, `schema-update`: the schema first |
| `map(true)` | `object((:), additional: true)` |
| `add-field(s, at, key, sub)` | `add-field(s, at + (key,), sub)` |
| `remove-field(s, at, key)` | `remove-field(s, at + (key,))` |
| `set-required(s, at, keys)` replacing the list | `set-required` adds `keys`; replace with `schema-update(s, at, o => (..o, required-keys: keys))` |

Validation is stricter in places: `date` takes only `YYYY-MM-DD`, and
`date-time` and `time` need an offset. The
[release notes](https://github.com/smur89/gairm-import/releases) list
every change.

## Reference

[REFERENCE.md](REFERENCE.md) documents every export.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Releases are cut by
[release-please](https://github.com/googleapis/release-please) from
conventional-commit titles on `main`.

## License

[MIT](LICENSE).
