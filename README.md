# json-resume

[![Build](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml/badge.svg)](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml)
[![License](https://img.shields.io/github/license/smur89/typst-json-resume)](LICENSE)

Load and validate canonical [JSON Resume](https://jsonresume.org/) data for any
Typst CV template. Strict to the published [schema](https://jsonresume.org/schema):
the loader rejects unknown fields and coerces strings to `content` where
renderers expect content. Renderer-specific extensions belong in the consuming
template, not here.

## Install

```typst
#import "@preview/json-resume:0.0.1": read-resume, validate-resume, coerce-resume, parse-resume
```

## Usage

The loader is a three-step pipeline you can run end-to-end with `parse-resume`
or step through individually:

```typst
#import "@preview/json-resume:0.0.1": parse-resume

// Common case — Typst's built-in json() reads the file relative to your
// document, parse-resume validates and coerces.
#let resume = parse-resume(json("resume.json"))
```

Step-by-step, if you want to handle validation errors yourself:

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

`read-resume(path)` is also exported as a convenience, but Typst resolves
paths against the file containing the call — so it requires a
**root-relative path** (one starting with `/`):

```typst
#let resume = parse-resume(read-resume("/resume.json"))
```

For paths relative to your own document, prefer `json("…")` over
`read-resume("/…")`.

The returned dict matches the canonical JSON Resume schema, with free-text
fields (`summary`, `description`, `highlights[]`, `reference`) coerced to
Typst `content`. Pass it into any compatible renderer — e.g. `altacv`:

```typst
#import "@preview/altacv:1.x": alta
#import "@preview/json-resume:0.0.1": parse-resume

#alta(..parse-resume(json("resume.json")), preferences: (...), labels: (...))
```

## Errors

`validate-resume` returns a list of `(path, message)` records — empty list
means the input is valid. `parse-resume` calls `validate-resume` first and
panics with a combined report on the first invocation that finds issues, so
every problem in the document surfaces in one error:

```
json-resume: found 3 problems in the input:
  - basics.email: expected string, got integer.
  - work[0].positon: unknown key "positon". Valid keys: name, location, description, position, url, startDate, endDate, summary, highlights.
  - meta.foo: unknown key "foo". Valid keys: canonical, version, lastModified.
```

## Scope

This package implements **only** the canonical [JSON Resume schema](https://jsonresume.org/schema).
Template-specific extensions (theme colours, header decorations, label
overrides, …) are layered on top by the consuming renderer — they do not
belong in the loader. Issues proposing renderer-specific fields will be closed
with a pointer to the relevant template repo.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Releases are cut by
[release-please](https://github.com/googleapis/release-please) from
conventional-commit titles on `main`.

## License

[MIT](LICENSE).
