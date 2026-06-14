# json-resume

[![Build](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml/badge.svg)](https://github.com/smur89/typst-json-resume/actions/workflows/build.yml)
[![License](https://img.shields.io/github/license/smur89/typst-json-resume)](LICENSE)

Load and validate canonical [JSON Resume](https://jsonresume.org/) data for any
Typst CV template. Strict to the published [schema](https://jsonresume.org/schema):
the loader rejects unknown fields and coerces strings to `content` where
renderers expect content. Renderer-specific extensions belong in the consuming
template, not here.

> **Status:** scaffolding only. `read-resume` / `parse-resume` are stubs that
> panic with a tracking link. The first tagged release will ship the first
> usable implementation.

## Install

```typst
#import "@preview/json-resume:0.0.1": read-resume, parse-resume
```

## Usage

```typst
#import "@preview/json-resume:0.0.1": read-resume, parse-resume

// File on disk → normalised dict.
#let resume = read-resume("resume.json")

// Already-parsed dict → normalised dict.
#let resume = parse-resume(json("resume.json"))
```

The returned dict matches the canonical JSON Resume schema, with string fields
that downstream renderers consume as `content` (e.g. `summary`,
`highlights[]`, `description`) already coerced. Pass it into any compatible
Typst CV template — e.g. `altacv`:

```typst
#import "@preview/altacv:1.x": alta
#import "@preview/json-resume:0.0.1": read-resume

#alta(..read-resume("resume.json"), preferences: (...), labels: (...))
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
