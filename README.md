<h1 align="center">gairm-import</h1>

<p align="center">
  <a href="https://typst.app/universe/package/gairm-import"><img alt="gairm-import on Typst Universe" src="https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Ftypst.app%2Funiverse%2Fpackage%2Fgairm-import&query=%2Fhtml%2Fbody%2Fdiv%2Fmain%2Fdiv%5B2%5D%2Faside%2Fsection%5B2%5D%2Fdl%2Fdd%5B3%5D&logo=typst&label=Universe&color=%23239DAE&style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/releases"><img alt="Latest GitHub release version of gairm-import" src="https://img.shields.io/github/v/release/smur89/gairm-import?style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/actions/workflows/build.yml"><img alt="GitHub Actions build workflow status on the gairm-import main branch" src="https://img.shields.io/github/actions/workflow/status/smur89/gairm-import/build.yml?style=flat-square"></a>
  <a href="LICENSE"><img alt="MIT license badge linking to the gairm-import LICENSE file" src="https://img.shields.io/github/license/smur89/gairm-import?style=flat-square"></a>
  <a href="https://github.com/smur89/gairm-import/stargazers"><img alt="Number of GitHub stargazers for gairm-import" src="https://img.shields.io/github/stars/smur89/gairm-import?style=flat-square"></a>
</p>

<p align="center">
  <strong>JSON Schema → Typst dict coercer.</strong>
  <br>
  Validate a JSON document against a JSON Schema (draft&nbsp;7 subset) and
  return a normalised Typst dict ready for downstream rendering. Ships with
  the <a href="https://jsonresume.org/schema">JSON Resume</a> schema and
  convenience entry points as the canonical bundled example.
</p>

<p align="center">
  <sub><em>"gairm" is Irish for vocation. The package was originally a JSON Resume loader.</em></sub>
</p>

## Contents

- [Highlights](#highlights)
- [Requirements](#requirements)
- [Quick start](#quick-start)
  - [Bring your own schema](#bring-your-own-schema)
  - [API at a glance](#api-at-a-glance)
- [Usage](#usage)
  - [Loading the document](#loading-the-document)
  - [The returned model](#the-returned-model)
  - [Rendering with a template](#rendering-with-a-template)
- [Errors](#errors)
  - [Handling validation errors yourself](#handling-validation-errors-yourself)
  - [Null handling](#null-handling)
  - [Strict null](#strict-null)
- [Schemas and composition](#schemas-and-composition)
  - [Two schemas](#two-schemas)
  - [Building a schema in Typst](#building-a-schema-in-typst)
  - [Format validation](#format-validation)
  - [Building an extension schema](#building-an-extension-schema)
  - [Targeted edits with lenses](#targeted-edits-with-lenses)
  - [Inspecting a schema](#inspecting-a-schema)
  - [JSON Pointer interop](#json-pointer-interop)
  - [Starting from a JSON Schema document](#starting-from-a-json-schema-document)
- [Contributing](#contributing)
- [License](#license)

## Highlights

- Strict validation with path-qualified error reports and "did you mean …?" hints.
- One-call `parse` that validates and coerces in a single step, or split via `validate` and `coerce`.
- Two flavours of the canonical JSON Resume schema: a faithful 1:1 derivation and a renderer-friendly strict variant.
- Bring your own JSON-Schema-shaped document via the `schema:` keyword — the engine is JSON-Schema-driven, not CV-specific.
- Functional, lens-based editing for extension schemas without re-spelling the canonical shape.
- A JSON Schema (draft 7 subset) → Typst schema translator for callers with an existing `.json` schema.

## Requirements

- Typst `0.15.0` or later.

## Quick start

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse

#let resume = parse(path("resume.json"))
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

The bundled schema is JSON Resume **1.7.0** (see the upstream
[changelog](https://github.com/jsonresume/jsonresume.org/blob/8576b3899489185193613b238bf3092efd005b45/packages/schema/CHANGELOG.md)
for what each version adds). It covers thirteen sections: `basics`, `work`,
`volunteer`, `education`, `awards`, `certificates`, `publications`, `skills`,
`languages`, `interests`, `references`, `projects`, `meta`. The top-level
`objective` string, the free-form `custom` object and the `$schema` metadata
field are also accepted. See
[jsonresume.org/schema](https://jsonresume.org/schema) for every field.

### Bring your own schema

gairm-import is JSON-Schema-driven, not CV-specific. Two ways to use a
non-CV shape.

**Translate an existing `.json` schema** with `schema-from-json-schema`
(JSON Schema draft 7 subset — supported keywords listed under
[Starting from a JSON Schema document](#starting-from-a-json-schema-document)):

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse, schema-from-json-schema

#let book-schema = schema-from-json-schema(json("book-schema.json"))
#let book = parse(path("book.json"), schema: book-schema)
```
<!-- x-release-please-end -->

**Or build the schema directly in Typst** with the public constructors (see
[Building a schema in Typst](#building-a-schema-in-typst)):

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  parse, object, array-of, string, number,
)

#let book-schema = object((
  title:  string(),
  author: string(),
  year:   number(),
  tags:   array-of(string()),
))

#let book = parse(path("book.json"), schema: book-schema)
```
<!-- x-release-please-end -->

Both go through the same `validate` / `coerce` / error-reporting
machinery — the JSON Resume schemas are just the bundled default. See
[Schemas and composition](#schemas-and-composition) for the full
schema-building API (lenses for targeted edits, the supported /
out-of-scope JSON Schema keywords, and more).

### API at a glance

The five names a first-time reader will meet. Lens, introspection, and
schema-building helpers are introduced later in [Schemas and composition](#schemas-and-composition).

| Export | Purpose |
|---|---|
| `parse(data, schema: ...)` | Validate and coerce in one call; aborts compilation with a combined report on errors. |
| `validate(data, schema: ...)` | Return a list of `(path, code, message, expected, got)` records — empty list means valid. |
| `coerce(data, schema: ...)` | Coerce a (validated) document into the typed model. |
| `resume-schema` | Default schema — faithful 1:1 derivation of the canonical JSON Resume document. |
| `resume-schema-strict` | Renderer-friendly overlay — free-text fields typed as Typst `content`, iso8601 `$ref` fields validated as dates. |
| `schema-from-json-schema(doc)` | Translate an existing JSON Schema (draft 7 subset) document — a dictionary, `path(..)` or bytes — into a Typst schema. Pair with `parse(..., schema: ...)`. |
| `object`, `array-of`, `string`, `number`, `integer`, … | Build a Typst schema directly. See [Schemas and composition](#schemas-and-composition). |

## Usage

### Loading the document

`parse` is the one-call entry point. The recommended form is
`parse(path("resume.json"))` — the
[`path`](https://typst.app/docs/reference/foundations/path/) value resolves
against your own `.typ` (not the `@preview` cache), so you can use the
natural relative path:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse

#let resume = parse(path("resume.json"))
```
<!-- x-release-please-end -->

A parsed dict or a `json("…")` wrap is also accepted — useful when you've
already loaded the document yourself:

```typst
// json() resolves the path against your .typ; parse takes the dict.
#let resume = parse(json("resume.json"))
```

Bytes work too, as with Typst's own `json`:

```typst
#let resume = parse(read("resume.json", encoding: none))
```

A string path is rejected: inside a package Typst resolves it against the
package, not your project, so `parse("/resume.json")` could never find your
file. Pass `path("resume.json")`.

The same input forms apply to `parse`, `validate`, `coerce` and
`schema-from-json-schema`: a dictionary, `path(..)` or bytes. `parse`,
`validate` and `coerce` also take any other root the schema accepts, such
as an array, or a string for a scalar schema such as `date-string`; they
panic on a string ending in `.json` that the schema's root does not take,
as a path it could never find. `schema-from-json-schema` panics on any
string.

### The returned model

The returned dict is a 1:1 mirror of the canonical schema — every kind comes
from the upstream JSON Schema document. Format-annotated fields are gated by
a regex (see [Format validation](#format-validation)); everything else passes
through as JSON-native types. For example:

```text
resume.basics.name            str
resume.basics.summary         str
resume.basics.email           str (gated as email)
resume.work.at(0).position    str
resume.work.at(0).highlights  array of str
resume.skills.at(0).keywords  array of str
```

For renderer-friendly opinions (free-text fields wrapped as Typst `content`,
iso8601 `$ref` fields validated as dates), import `resume-schema-strict`
instead and pass it via the `schema:` keyword — see
[Two schemas](#two-schemas).

### Rendering with a template

Pass the model into any compatible renderer — e.g. [`altacv`](https://typst.app/universe/package/altacv):

<!-- Two fences (not one): a single fence would let release-please rewrite this altacv pin on every gairm release. Bump it by hand when altacv publishes a new version. See https://github.com/typst/packages/pull/5069#discussion_r3420827761 -->

```typst
#import "@preview/altacv:1.7.0": alta
```

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse

#alta(parse(path("resume.json")))
```
<!-- x-release-please-end -->

If the renderer expects fields outside the canonical JSON Resume shape, build
an extension schema with the public combinators and pass it as `schema:` —
see [Building an extension schema](#building-an-extension-schema).

## Errors

`validate` returns a list of `(path, code, message, expected, got)` records
— empty list means the input is valid. `parse` validates first and aborts
compilation with a combined report on the first invocation that finds
issues, so every problem in the document surfaces in one error. A document
with a numeric `basics.email` and two stray keys, parsed with
`schema: resume-schema-strict`:

```text
error: panicked with: gairm-import: found 3 problems in the input:
  - basics.email: expected string, got integer.
  - work[0].positon: unknown key "positon". Did you mean "position"?
  - meta.foo: unknown key "foo". Valid keys: canonical, version, lastModified.
```

When a typo is within edit distance 2 of a valid key, the message surfaces
a short "Did you mean …?" hint; otherwise it falls back to the full
valid-keys list shown for `meta.foo`. The default `resume-schema` reports
only the first problem: upstream lets undeclared keys through at those
positions (see [Two schemas](#two-schemas)).

### Handling validation errors yourself

Each error is a record `(path, code, message, expected, got)`:

```typst
(
  path: ("basics", "email"),
  code: "type",
  message: "expected string, got integer.",
  expected: "string",
  got: "integer",
)
```

`code` says what kind of problem it is, so you can branch on it rather
than on the message. `expected` and `got` hold the data behind the
message, or `none` where a code has nothing to put there:

| `code` | Meaning | `expected` | `got` |
|---|---|---|---|
| `type` | The value's JSON type is wrong (also: an enum or union none of whose members takes that type) | The type name(s) | The value's type name |
| `required` | A required key is missing | | |
| `unknown-key` | A key the object doesn't declare | The valid keys | The key |
| `dependent` | A key required by another key's presence is missing | The missing key | The key that requires it |
| `enum` | Not one of the enum's values | The values | The value |
| `format` | Not in the format's shape (date, email, …) | The format's description | The value |
| `pattern` | Doesn't match the pattern | The pattern's description | The value |
| `length` | String too short or too long | The broken bound, keyed by its constraint: `(min-length: 3)` or `(max-length: 80)` | The length |
| `range` | Number below the minimum or above the maximum | The broken bound, keyed by its constraint: `(minimum: 1)`, `(exclusive-minimum: 1)`, `(maximum: 10)` or `(exclusive-maximum: 10)` | The number |
| `multiple` | Number not a multiple of `multiple-of` | `(multiple-of: 0.1)` | The number |
| `integer` | A number with a fractional part where an integer is expected | | The number |
| `items` | Too few or too many array items | The broken bound, keyed by its constraint: `(min-items: 1)` or `(max-items: 5)` | The item count |
| `unique` | Duplicate array items | | The two duplicate indices |
| `union` | Several alternatives take the value's type but none matches, or more than one matches a `one-of` | The alternatives' kinds | |
| `not` | The value matches a `not-of` schema | | |

`format-errors` reads only `path` and `message`.

To present errors yourself instead of letting `parse` abort compilation,
run the two steps separately:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": validate, coerce

#let raw = json("resume.json")
#let errors = validate(raw)
#if errors.len() > 0 {
  [Resume has #errors.len() issue(s).]
} else {
  let model = coerce(raw)
  // render model …
}
```
<!-- x-release-please-end -->

### Null handling

JSON `null` is treated as if the key were absent — no validation error,
dropped from the coerced model. Null elements inside arrays are dropped the
same way. This matches the convention used by most JSON Resume emitters,
where `"summary": null` is semantically equivalent to omitting the key.
Only `null` itself is absent: an object whose keys are all `null`, or an
empty object, stays in the model as an empty dictionary, so
`{"basics": {"name": null}}` coerces to `(basics: (:))`.
Unknown keys are still flagged even when their value is `null`, so typos do
not slip through silently. The one exception is a free-form object with no
declared fields (JSON Resume's `custom`): it is passed through exactly as
given, nulls and all, as upstream asks tools to do.

Root null is rejected: if the entire input document is `null`, `validate`,
`coerce`, `parse` and `schema-from-json-schema` panic with
`gairm-import: input must be a dict, got null.` The null-as-absent policy
applies to leaf positions inside a document, not to the document itself.

### Strict null

When `null` must mean something, pass `strict-null: true` to `parse`,
`validate` or `coerce`. `null` is then an ordinary value that a schema
accepts or rejects, and only a missing key is missing:

| Input | Default | `strict-null: true` |
|---|---|---|
| required key missing | `required` | `required` |
| key holding `null`, field not nullable | `required` if required, else dropped | `type`, "got null" |
| key holding `null`, field `nullable(X)` | dropped | accepted, kept as `none` |
| `null` array element | dropped | `type`, or kept if the element is `nullable(X)` (and counted by `min-items` / `unique-items`) |
| dependent-required trigger holding `null` | does not fire | fires |

A root `null` still panics, and a free-form object (no fields,
`additional: true`) still passes through as given.

`nullable(X)` is `any-of((X, null-type))`: it accepts `null` or whatever
`X` accepts, and judges a non-null value exactly as `X` does, messages
included. `describe-schema` draws it as `X?`. Without `strict-null` it
behaves as `X`, since every field already treats `null` as absent.
`schema-from-json-schema` translates `type: [X, "null"]` to `nullable(X)`.

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse, object, str-type, nullable

#let schema = object(
  (name: str-type, nickname: nullable(str-type)),
  required-keys: ("name", "nickname"),
)
#parse((name: "Ada", nickname: none), schema: schema, strict-null: true)
// → (name: "Ada", nickname: none)
```
<!-- x-release-please-end -->

JSON Resume's upstream schema declares no nullable fields, so
`strict-null: true` with `resume-schema` (or `resume-schema-strict`)
rejects every `null` in a résumé. Use it with your own schema, or a
translated one that says `"null"` where it means it.

## Schemas and composition

### Two schemas

The package exports two values of the canonical schema:

- **`resume-schema`** — a faithful 1:1 translation of the vendored upstream
  JSON Schema document. Every kind comes from the source; nothing is
  rewritten. This is the default when you call `parse(data)` /
  `validate(data)` / `coerce(data)`.
- **`resume-schema-strict`** — adds three layered opinions on top via the
  lens API:
  - free-text fields (`basics.summary`, `work[].summary`,
    `work[].highlights[]`, etc.) are typed as Typst `content` so they
    splice directly into markup
  - iso8601 `$ref` fields (`startDate`, `endDate`, …) are validated as
    ISO-8601 dates (the upstream document doesn't carry a `format`
    annotation on them, just a regex inside a definition)
  - upstream's `additionalProperties: true` markers — declared at the top
    level and on every section's items, so the faithful default lets
    undeclared extras pass through — are stripped recursively, restoring
    the "unknown keys are rejected" promise (typed extras via
    `additionalProperties: <schema>` are kept, and so is upstream's
    free-form `custom` object, which declares no fields of its own)

Pass `schema: resume-schema-strict` to opt in:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": parse, resume-schema-strict

#let resume = parse(path("resume.json"), schema: resume-schema-strict)
```
<!-- x-release-please-end -->

The faithful default is the source-of-truth view; the strict variant is a
renderer-ergonomics overlay. If you want a different mix, build your own by
lensing over `resume-schema` — see
[Targeted edits with lenses](#targeted-edits-with-lenses).

### Building a schema in Typst

A schema is a plain dictionary, built by functions. As with Typst's own
functions (`text(size:)`, `rect(stroke:)`), the options are named
arguments, and an argument you leave out sets nothing:

| Constructor | Arguments |
|---|---|
| `string(..)` | `min-length`, `max-length`, `format`, `pattern`, `expected` |
| `number(..)` | `minimum`, `maximum`, `exclusive-minimum`, `exclusive-maximum`, `multiple-of` |
| `integer(..)` | the same as `number`; the value must also have no fractional part (`1.0` passes, `1.5` fails) |
| `array-of(elem, ..)` | `min-items`, `max-items`, `unique-items` |
| `object(shape, ..)`, `map(value)` | see [Building an extension schema](#building-an-extension-schema) |
| `any-of(..)`, `one-of(..)`, `not-of(..)`, `nullable(..)`, `enum-of(..)`, `const-of(..)` | see [Starting from a JSON Schema document](#starting-from-a-json-schema-document) |

Each argument is the JSON Schema keyword of the same meaning in kebab-case
(`min-length` is `minLength`), checked by the same rule
`schema-from-json-schema` applies: a value of the wrong type, or bounds no
value can satisfy, panics when the schema is built.

- `format` takes a JSON Schema format name, one of the nine under
  [Format validation](#format-validation): `string(format: "email")`.
- `pattern` takes a `regex` or a pattern string, and `expected` says what a
  match looks like, for the error message (`expected …`). With a `format`
  as well, the string must have the format and match the pattern.

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  object, array-of, string, number, integer,
)

#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
  ),
  required-keys: ("name", "email"),
)
```
<!-- x-release-please-end -->

With no arguments, `string()`, `number()` and `integer()` equal the
constants `str-type`, `number-type` and `integer-type`, which stay as
aliases until 1.0; prefer the constructors. `string(format: "email")`
equals `email-string`, and `string(pattern: p, expected: e)` equals
`pattern-string(p, expected: e)`, so those constants and `pattern-string`
keep working (in `paths-of-kind`, too). `content-type`, `bool-type`,
`null-type` and `any-type` take no constraints and stay constants.

### Format validation

Fields the canonical schema annotates with `format: "uri"`, `format: "email"`,
or `format: "date"` are gated by a regex during `validate` / `parse`. The
patterns are deliberately permissive — they reject obvious malformations
without claiming full RFC compliance — and each emits a path-qualified
message with a canonical example (shown here under `resume-schema-strict`;
in `resume-schema` the date fields are upstream's regex, and the message
quotes it — see below). A `uri` is any scheme, then `:` and no
whitespace (`https://…`, `mailto:…`, `urn:…`); an `email`'s domain may be a
single label (`name@host`) or an address literal (`name@[127.0.0.1]`), and
its local part may be quoted (`"joe bloggs"@example.com`):

```text
basics.email:           expected an email (e.g. "name@example.com").
basics.url:             expected a URI (e.g. "https://example.com").
certificates[0].date:   expected an ISO-8601 date (e.g. "2024-01-15").
```

Five more formats are available through `string(format: …)`,
`schema-from-json-schema` or a lens override (the canonical document doesn't
use them), each with the same
permissive philosophy:

| `format`   | kind              | accepts                                                  |
| ---------- | ----------------- | -------------------------------------------------------- |
| `uuid`     | `uuid-string`     | 8-4-4-4-12 hex digits, any case                          |
| `hostname` | `hostname-string` | dot-separated labels of letters, digits, inner hyphens   |
| `ipv4`     | `ipv4-string`     | dotted quad, octets 0-255, no leading zeros              |
| `ipv6`     | `ipv6-string`     | hex groups with `::` compression; no embedded-IPv4 tail  |
| `time`     | `time-string`     | `HH:MM:SS`, optional fraction, optional `Z` / `±HH:MM`; leap second, `z` |

`format: "date-time"` maps to the separate `datetime-string` kind:
`date-string` accepts `YYYY` / `YYYY-MM` / `YYYY-MM-DD`, while
`datetime-string` requires the full `YYYY-MM-DDTHH:MM:SS` shape (optional
fractional part and `Z` / `±HH:MM` offset). As in RFC 3339, both date-time
and `time` take `T` / `Z` in either case and a leap second (`23:59:60Z`;
second 60 at minute 59, or at any minute under an offset with minutes). The canonical document carries
no `date-time` annotations, so that kind only fires via
`schema-from-json-schema` or a lens override.

Data written in Typst can give `date-string` a `datetime` with a date and no
time, and `datetime-string` one with both; each is checked and returned as
the ISO string (`"2024-01-05"`, `"2024-01-05T09:03:07"`). A `datetime` of
the other shape is rejected rather than truncated. In `resume-schema` the
resume's date fields are patterned strings (see below), so a `datetime` there
needs `resume-schema-strict`.

Every date field in JSON Resume (`work[].startDate`, `awards[].date`,
`certificates[].date`, …) uses `$ref: "#/definitions/iso8601"` rather than
`format: "date"`. That definition is a string with a regex, so in
`resume-schema` those fields are strings with a `pattern`, upstream's regex
(`YYYY`, `YYYY-MM` or `YYYY-MM-DD`, month and day in range).
`meta.lastModified` has no regex upstream and stays a plain `string`. Switch to
`resume-schema-strict` to type them all as `date-string` (and
`meta.lastModified` as the upstream-described `YYYY-MM-DDThh:mm:ss`
`datetime-string`, or a bare `date-string`), or build your own override list
with `lens-put(schema, path, date-string)`.

Coercion is pass-through: format-checked values flow through to the model as
plain strings, so renderers receive `model.basics.email == "name@example.com"`
unchanged (a `datetime` given to a date kind becomes its ISO string).

For ad-hoc constraints outside the built-in formats, build a
`string(pattern: re, expected: …)` (`re` is a `regex` or a pattern string;
`pattern-string(re, expected: …)` is the same schema) and target it via a
lens or splice it into an extension schema. JSON
Schema's `pattern` keyword on a plain string maps to this kind too — see
[Starting from a JSON Schema document](#starting-from-a-json-schema-document)
for how it combines with `format`:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  resume-schema, lens-put, pattern-string,
)

// Gate basics.location.countryCode as an ISO 3166-1 alpha-2 code.
#let with-country-code = lens-put(
  resume-schema,
  ("basics", "location", "countryCode"),
  pattern-string(
    "^[A-Z]{2}$",
    expected: "an ISO 3166-1 alpha-2 code (e.g. \"US\")",
  ),
)
```
<!-- x-release-please-end -->

Typst's regex `match` finds a match anywhere in the string, so anchor the
pattern yourself if you need a full-string match — `^…$` is the common case.

### Building an extension schema

`parse` is strict against declared fields in the canonical schema: keys that
aren't declared *and* aren't covered by an upstream `additionalProperties`
clause are rejected. (Upstream JSON Resume sets `additionalProperties: true`
at the top level and on every section's items, so extras in those positions
pass through —
[Two schemas](#two-schemas) covers the strict variant that strips them.)

Renderers that expect their own top-level fields in the resume document
(e.g. alta-typst's `focusAreas`) can build a JSON-Resume+ schema with the
public combinators and pass it to `parse` / `validate` / `coerce` via the
`schema:` keyword:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  resume-schema, parse, add-field, array-of, content-type,
)

// Add a renderer-specific field at the top level (the empty path).
#let altacv-schema = add-field(
  resume-schema, (), "focusAreas", array-of(content-type),
)

#let model = parse(path("resume.json"), schema: altacv-schema)
```
<!-- x-release-please-end -->

`add-field` keeps everything else about the object, including upstream's
`additionalProperties: true`. Splicing the shape into a new object,
`object((..resume-schema.shape, focusAreas: …))`, does not: `object()`
defaults to rejecting undeclared keys, so it silently closes the top level.
Per-section combinators (`work-item`, `volunteer-item`, …) are
intentionally not exposed yet — reach a section through a path, as in
[Targeted edits with lenses](#targeted-edits-with-lenses).

`object` also takes `dependent-required`, a map from a key to the keys that
must be present whenever it is; a `null` value counts as absent, as with
`required-keys`.

```typst
#object(
  (phone: str-type, email: str-type),
  dependent-required: (phone: ("email",)),
)
```

### Targeted edits with lenses

`add-field` at the empty path covers top-level additions. When the field
you want to touch is three or four levels deep (`work` items'
`highlights` element schema, `basics.email`, …), lenses target a path inside the schema and return a new schema with
the targeted node replaced or transformed:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  resume-schema, resume-schema-strict, lens, lens-put, lens-over,
  add-field, set-required, unset-required, str-type, number-type,
)

// resume-schema-strict types basics.summary as content (rich); put str
// (plain) back if you want the summary rendered as plain text instead:
#let plain-summary = lens-put(
  resume-schema-strict, ("basics", "summary"), str-type,
)

// Add a numeric `rating` to every language entry — touches
// resume-schema.shape.languages.elem.shape without re-spelling the wrapper:
#let with-rating = add-field(
  resume-schema, lens(("languages", "items")), "rating", number-type,
)

// Transform an existing node with a function (spreading `meta` keeps
// its `additional` and `required-keys`):
#let with-extra-meta = lens-over(
  resume-schema,
  ("meta",),
  meta => (..meta, shape: (..meta.shape, source: str-type)),
)

// Make basics.name and basics.email required for your template
// (canonical schema declares no required keys). A lens names a location
// you reuse:
#let basics = lens(("basics",))
#let strict-basics = set-required(resume-schema, basics, ("name", "email"))

// Relax email back without re-spelling the rest of the required list:
#let mixed-basics = unset-required(strict-basics, basics, ("email",))
```
<!-- x-release-please-end -->

Path segments match JSON Schema keyword names: object keys as strings, the
literal `"items"` to enter an array's element schema, and the literal
`"additionalProperties"` to enter an object's `additional` (the
additionalProperties schema; only valid when `additional` is a schema dict,
not `true`). A union member is entered by its index (`("meta",
"lastModified", 0)`, the same for `any-of` and `one-of`) and a `not-of`
member by the literal `"not"`, so `lens-put` can replace one member and
keep the rest. Composition (`lens-then(a, b)`) concatenates paths, so
`lens-then(lens(("work",)), ("items", "highlights"))` is the same
lens as `lens(("work", "items", "highlights"))`. The empty path `()`
is the identity lens.

The schema always comes first, so edits chain through `.fold`. A location
is a lens, `lens(path)` (the dictionary `(lens: path)`), or the bare path
array: every function that takes a location takes either, and `kind-at`
too.

| Function | Shape | Behaviour |
|---|---|---|
| `lens(path)` | `path → lens` | Construct a lens from a path tuple |
| `lens-get(schema, at)` | `schema, at → sub-schema` | Read the targeted node |
| `lens-put(schema, at, value)` | `schema, at, sub → schema` | Replace the targeted node |
| `lens-over(schema, at, fn)` | `schema, at, (sub → sub) → schema` | Apply a function to the targeted node |
| `lens-then(a, b)` | `at, at → lens` | Compose two locations (path concatenation) |
| `add-field(schema, at, key, sub)` | … → schema | Add a key to the object at `at` |
| `remove-field(schema, at, key)` | … → schema | Remove a key from the object at `at` |
| `set-required(schema, at, keys)` | … → schema | Replace the object's `required-keys` list at `at` |
| `unset-required(schema, at, keys)` | … → schema | Drop specific entries from the object's `required-keys` list at `at` |

**Deprecated, accepted until 1.0:** the lens-first order
`lens-get(at, schema)`, `lens-put(at, schema, value)` and
`lens-over(at, schema, fn)`, and the old lens shape
`(kind: "lens", path: …)` wherever a location is taken. Arguments are
told apart by type, so an old call still works unchanged; a call that is
neither a schema then a location nor the old order panics.

Operations are functional — each helper above returns a NEW schema and
leaves the input untouched, so you can chain edits without disturbing the
canonical one. (Operations are top-level functions rather than methods
because Typst parses `lens.put(…)` as a type-method lookup, not a closure
call.)

### Inspecting a schema

When an extension schema misbehaves, `describe-schema`, `paths-of-kind`,
and `kind-at` answer the three usual questions — *what does this thing
look like?*, *where do my date strings live?*, *what kind is at this
path?* — without `repr(schema)` or hand-walking `.shape`:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  resume-schema-strict, describe-schema, paths-of-kind, kind-at, date-string,
)

// Tree view of every leaf, with array sections suffixed `[]` and union
// members listed under their field by index.
#describe-schema(resume-schema-strict)
// basics:
//   email    email-string
//   name     string
//   summary  content
//   …
// meta:
//   canonical     uri-string
//   lastModified  any of:
//     [0]  datetime-string
//     [1]  date-string
//   version       string
// …
// work[]:
//   highlights[]  content
//   location      one of:
//     [0]  string
//     [1]:
//       address      string
//       …
//   startDate     date-string
//   …

// Every lens-compatible path whose terminal kind matches, inside union
// members too.
#paths-of-kind(resume-schema-strict, date-string)
// → (("awards", "items", "date"), …, ("meta", "lastModified", 1), …)

// Kind at a single path — thin wrapper over lens-get.
#kind-at(resume-schema-strict, ("basics", "summary"))  // "content"
#kind-at(resume-schema-strict, ("meta", "lastModified", 0))  // "datetime-string"
```
<!-- x-release-please-end -->

`describe-schema` marks what a node sets beyond its kind. A required field
is suffixed `*` (`name*  string`), constraints follow the kind in brackets
(`string (min-length 1, max-length 80)`, `integer (minimum 0)`,
`tags[]  string (min-items 1, unique-items)`), a string with a pattern
draws as `string + pattern`, a union lists its members as
`[0]`, `[1]`, … under an `any of:` or `one of:` header (a `nullable(X)`
draws as `X?`), a `not` member shows
under its field as `not`, and an object's `dependent-required` entries close
its block as `phone → email`. Neither JSON Resume schema has required
fields or constraints, so they show none of these.

`paths-of-kind` takes the kind as a value: a schema node such as
`date-string` (matched by kind, so `number-type` finds numbers and
`integer-type` integers), or a constructor such as `pattern-string`. The kind
name as a string (`"date-string"`) still works but is deprecated, and will be
removed in the next major version.

`integer` is a kind of its own: `kind-at` returns `"integer"` for an integer
field, `paths-of-kind(s, number-type)` no longer lists integers, and
`describe-schema` prints `integer` where it printed `number (integer)`.
Validation and coercion are unchanged.

Array segments in returned path tuples use `"items"`, union members their
index and a `not` member `"not"`, so they plug straight into the lens
functions as locations;
the `[]` suffix and `[0]` labels in `describe-schema`'s output are
human-friendly visual only. `paths-of-kind` and the lens functions reach
into union and `not` members, so `paths-of-kind(…, any-of)` returns the
union and `paths-of-kind(…, date-string)` a date member inside it. Keys
sort alphabetically so diffs across schema versions stay stable.

The real leverage comes from folding `paths-of-kind` together with
`lens-put` to bulk-edit every field of a kind in one pass — the list of
paths is derived from the schema, so new fields an upstream JSON Resume
bump introduces are covered automatically:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  resume-schema, paths-of-kind, lens-put, pattern-string, uri-string,
)

// Tighten every uri-string field to a corporate-domain pattern,
// without enumerating the paths by hand.
#let corporate-uri = pattern-string(
  "^https://(corp|docs)\.example\.com/",
  expected: "a corporate URL",
)
#let corporate-schema = paths-of-kind(resume-schema, uri-string).fold(
  resume-schema,
  (schema, path) => lens-put(schema, path, corporate-uri),
)
```
<!-- x-release-please-end -->

### JSON Pointer interop

Lens paths and validator error paths are `(seg, seg, ...)` tuples — natural
in Typst but they don't directly interoperate with external tooling that
speaks [RFC 6901 JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901)
(editor extensions for schema-aware completion, schema diff tools, JSON
Schema documentation generators, …). `path-to-pointer` / `pointer-to-path`
cross the boundary:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": path-to-pointer, pointer-to-path

#path-to-pointer(("basics", "email"))            // "/basics/email"
#path-to-pointer(("work", 0, "highlights", 1))   // "/work/0/highlights/1"
#path-to-pointer(("a/b",))                       // "/a~1b"     — `/` escapes as `~1`
#path-to-pointer(("~tilde",))                    // "/~0tilde"  — `~` escapes as `~0`

#pointer-to-path("/work/0/highlights/1")         // ("work", 0, "highlights", 1)
#pointer-to-path("")                             // ()          — whole document
#pointer-to-path("/")                            // ("",)       — empty-string key at root
```
<!-- x-release-please-end -->

**Two addressing schemes share the same encoder.** Validator error paths
(mixed `str` / non-negative `int`) address into **data** — the output is a
real RFC 6901 pointer any JSON-Pointer-aware tool can dereference against
the document. Lens and introspect paths (`str` segments with `"items"`,
`"additionalProperties"` and `"not"`, plus an `int` for a union member)
address into the **schema** — the output names a
schema location the way JSON Schema tooling does in `$ref`
(e.g. `#/properties/foo/items`), not a data position.

Malformed input panics rather than passing through silently: non-`str`/`int`
or negative segments at encode, invalid `~` escapes at decode.
`pointer → path → pointer` round-trips losslessly; `path → pointer → path`
is lossless except for `str` segments that look like array indices
(`("0",)` decodes back as `(0,)`) — which validator and lens paths never
emit in practice.

### Starting from a JSON Schema document

`schema-from-json-schema(parsed-schema)` translates a JSON Schema (draft 7
subset) into a Typst schema dict. Use it when you already have an
authoritative `.json` schema and don't want to keep a parallel Typst copy
in sync:

<!-- x-release-please-start-version -->
```typst
#import "@preview/gairm-import:0.10.1": (
  schema-from-json-schema, coerce, object, array-of, content-type,
)

#let canonical = schema-from-json-schema(path("resume-schema.json"))
#let altacv-schema = object((
  ..canonical.shape,
  focusAreas: array-of(content-type),
))

#let model = coerce(json("resume.json"), schema: altacv-schema)
```
<!-- x-release-please-end -->

**Supported keywords:**

- `type`: `string` / `number` / `integer` / `array` / `object` / `boolean` /
  `null` — `integer` rejects numbers with a non-zero fractional part
  (`1.0` passes, per draft-7 semantics); the matching Typst-side
  constructor is `integer()`
- `format`: `uri` → `uri-string`, `email` → `email-string`,
  `date` → `date-string`, `date-time` → `datetime-string`,
  `uuid` → `uuid-string`, `hostname` → `hostname-string`,
  `ipv4` → `ipv4-string`, `ipv6` → `ipv6-string`, `time` → `time-string`
- `pattern` → `pattern-string` on a plain string schema; alongside
  `format`, both apply (the format kind gains the pattern as an extra gate,
  checked after the format's own check, also for a `datetime` given to a
  date kind)
- `enum` → `enum-of`, `const` → `const-of` — `type` and constraint keywords
  beside them (`minLength`, `minimum`, `minItems`, `pattern`, `format`, …) are
  folded in at translate time: only values satisfying them are kept, and
  a keyword ignores values of a type it does not apply to (`minimum`
  leaves a string value alone, per JSON Schema). If no value survives the
  schema is unsatisfiable and panics. `properties` / `required` /
  `additionalProperties` / `items` / `dependentRequired` / `dependencies`
  beside them panic
- `properties`, `required`, `items` — `type: "array"` without `items` takes
  items of any value (`array-of(any-type)`)
- Nodes with no `type` (draft 7): `{}`, or a node of annotations only,
  → `any-type`, which accepts every value (and `null` under
  `strict-null`) and passes it to the model unchanged (`describe-schema`
  shows `any`). With type-specific
  keywords (`{minLength: 2}`, `{format: "date"}`, `{properties: …}`) it is
  an `any-of` over one member per JSON type — boolean, object, array,
  number, string, then null, as for a `type` array — each keyword narrowing only its own type's member, as
  for a `type` array; the other members take any value of their type (an
  object member with no `properties` is open). A string failing
  `minLength` there still reports `expected string length ≥ 2, got 1.`
- `dependentRequired`, and draft 7's array-form `dependencies`
  (`dependencies: (a: ("b", "c"))`) → `dependent-required`; only on
  `type: "object"` schemas, and `allOf` unions the lists per trigger
- Internal `$ref` (`#/definitions/…` / `#/$defs/…`), a URI fragment:
  percent-decoded first (`%25` is `%`, `%22` is `"`), then read as an
  RFC 6901 pointer: `~1` is `/`, `~0` is `~`, and a numeric segment
  indexes an array (`#/definitions/pair/anyOf/0`) — like a composition
  keyword, `$ref` must stand alone (annotation-only siblings excepted); a
  sibling `minLength`, `type`, etc. panics rather than being silently
  dropped as draft 7 would
- `anyOf` → `any-of` (at least one member matches), `oneOf` → `one-of`
  (exactly one member matches), `not` → `not-of` (value must not match) —
  the composition keyword must stand alone on its node (annotation-only
  siblings like `title` / `description` excepted); a sibling `type`,
  constraint, or `$ref` panics rather than being silently ignored
- `allOf` — merged at translate time; every member must be an object
  schema (shapes union, `required` union; a duplicate key must carry an
  identical sub-schema; `additionalProperties` must agree across all
  members, with an undeclared member counting as closed). Members with
  `additionalProperties: false` or a schema must declare the same
  properties, since draft 7 applies each member's `additionalProperties`
  to its own properties only. A `type: ["object", "null"]` member merges
  as its object, and the result is nullable only when every member is.
  Non-object composition (e.g. string + extra constraints) panics
- `type: [X, "null"]` → `nullable(X)`, which behaves as `X` by default
  and accepts `null` under [`strict-null: true`](#strict-null); lenses
  and `paths-of-kind` reach `X` as member `0`
- `type: [A, B, ...]` unions → `any-of` over one member per type, with a
  final `null-type` member when `"null"` is listed. Type-specific keywords (`minLength`, `minimum`, `items`,
  ...) apply only to the member of their own type, as in JSON Schema
- String constraints: `minLength`, `maxLength`
- Number constraints: `minimum`, `maximum`, `exclusiveMinimum`,
  `exclusiveMaximum`, `multipleOf`
- Array constraints: `minItems`, `maxItems`, `uniqueItems`
- `minLength`, `maxLength`, `minItems` and `maxItems` take a non-negative
  integer; a whole-number float (`2.0`) counts, as it does for `integer`
- `additionalProperties`: a schema, `true`, or `false` — `false` matches
  the strict default; `true` permits extras without validation; a schema
  validates every extra against it (also reachable via the
  `map(value-schema)` combinator)

Constraint keywords are baked onto the kind dict as kebab-case fields and
validated inline: the same fields the constructors' arguments set, so
`schema-from-json-schema((type: "string", minLength: 3))` equals
`string(min-length: 3)`.

**Out of scope.** Each keyword below panics with a clear "unsupported"
message rather than silently dropping the constraint:

- `if` / `then` / `else`
- `dependentSchemas`, and the schema form of `dependencies` — these need
  conditional schemas, which are out of scope
- `type: "object"` with neither `properties` nor `additionalProperties`
  (fully open). This one is deliberate, not a gap: the engine rejects
  undeclared keys by default, so a schema that wants an open object says
  so with `additionalProperties: true`
- External `$ref`
- Boolean schemas (`true` / `false` as a subschema, e.g.
  `properties: (a: true)`); `additionalProperties: true` / `false` is
  supported
- String formats other than the nine listed above
- `allOf` with non-object members, `allOf` whose closed or typed members
  declare different properties, and schema-bearing sibling keywords
  beside any composition keyword or `$ref` (move them into the members or
  the referenced definition)
- Any keyword not listed under "Supported keywords" — e.g.
  `minProperties`, `maxProperties`, `patternProperties`, `propertyNames`,
  `contains`, `additionalItems`, or a misspelling like `minLenght`. Draft 7
  would ignore an unknown keyword; here it panics, naming the keyword. A
  supported keyword of another JSON type (`minimum` on a string) is
  ignored, as in draft 7
- A JSON `null` as the value of a keyword (`type: null`, `items: null`,
  …), rather than reading it as absent. Annotations such as `title` or
  `default` may be null, `const: null` means the value must be null,
  and `enum` may list null

One failure doesn't come with the translator's own message: an invalid
regex in `pattern` (e.g. `"("`) fails with Typst's regex parse error,
since Typst can't catch it to report it as a translator error.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Releases are cut by
[release-please](https://github.com/googleapis/release-please) from
conventional-commit titles on `main`.

## License

[MIT](LICENSE).
