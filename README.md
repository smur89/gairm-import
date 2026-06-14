# json-resume

[![Build](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml/badge.svg)](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml)
[![License](https://img.shields.io/github/license/smur89/typst-json-resume)](LICENSE)

[JSON Resume](https://jsonresume.org/) is a portable JSON-based resume format —
one `resume.json` file rendered by many themes across many output formats.
This package brings that ecosystem to Typst: load and validate a canonical
`resume.json`, then hand the normalised dict to any compatible Typst CV
template. Strict to the published [schema](https://jsonresume.org/schema):
unknown fields are rejected, free-text fields are coerced to Typst `content`,
and renderer-specific extensions belong in the consuming template — not here.

Motivated by [smur89/alta-typst#48](https://github.com/smur89/alta-typst/issues/48).

## Install

```typst
#import "@preview/json-resume:0.0.1": validate-resume, coerce-resume, parse-resume
```

## A minimal `resume.json`

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

The full canonical schema covers thirteen sections:
`basics`, `work`, `volunteer`, `education`, `awards`, `certificates`,
`publications`, `skills`, `languages`, `interests`, `references`, `projects`,
`meta`. The `$schema` top-level metadata field is also accepted. See
[jsonresume.org/schema](https://jsonresume.org/schema) for every field.

## Usage

`parse-resume` is the one-call entry point. It accepts either a parsed dict
or a Typst-root-relative path string:

```typst
#import "@preview/json-resume:0.0.1": parse-resume

// Path relative to your own .typ — let Typst's json() resolve it.
#let resume = parse-resume(json("resume.json"))

// Or a Typst-root-relative path string, resolved by parse-resume itself.
#let resume = parse-resume("/resume.json")
```

The returned dict mirrors the canonical schema. Free-text fields (`summary`,
`description`, `highlights[]`, `reference`) are coerced to Typst `content`;
everything else stays as JSON-native types. For example:

```typst
resume.basics.name            // str — "Seán Ó Murchú"
resume.basics.summary         // content — wrapped for direct rendering
resume.work.at(0).position    // str
resume.work.at(0).highlights  // (content, content, …)
resume.skills.at(0).keywords  // (str, str, …) — tag-like, not coerced
```

Pass the model into any compatible renderer — e.g. `altacv`:

```typst
#import "@preview/altacv:1.1.1": alta
#import "@preview/json-resume:0.0.1": parse-resume

#alta(parse-resume(json("resume.json")), preferences: (...), labels: (...))
```

### Handling validation errors yourself

```typst
#import "@preview/json-resume:0.0.1": validate-resume, coerce-resume

#let raw = json("resume.json")
#let errors = validate-resume(raw)
#if errors.len() > 0 [
  // each error is `(path: (...), message: "...")`
  Resume has #errors.len() issue(s).
] else [
  #let model = coerce-resume(raw)
  ...
]
```

## Errors

`validate-resume` returns a list of `(path, message)` records — empty list
means the input is valid. `parse-resume` calls `validate-resume` first and
aborts compilation with a combined report on the first invocation that finds
issues, so every problem in the document surfaces in one error:

```
error: assertion failed: json-resume: found 3 problems in the input:
  - basics.email: expected string, got integer.
  - work[0].positon: unknown key "positon". Valid keys: name, location, description, position, url, startDate, endDate, summary, highlights.
  - meta.foo: unknown key "foo". Valid keys: canonical, version, lastModified.
```

## Scope

This package implements **only** the canonical JSON Resume schema.
Template-specific extensions (theme colours, header decorations, label
overrides, …) are layered on top by the consuming renderer. Requests for
renderer-specific fields will be redirected to the relevant template repo.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Releases are cut by
[release-please](https://github.com/googleapis/release-please) from
conventional-commit titles on `main`.

## License

[MIT](LICENSE).
