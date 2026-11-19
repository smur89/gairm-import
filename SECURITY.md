# Security policy

## Reporting a vulnerability

If you've found a security issue in `gairm-import`, please **do not** open a
public issue.

Instead, open a private report via [GitHub Security Advisories](https://github.com/smur89/gairm-import/security/advisories/new).
I'll acknowledge within a few days and work with you on a fix.

## Scope

`gairm-import` is a Typst data-loading library: it reads a JSON document
(a path, bytes or a Typst value), checks it against a schema the caller
supplies, and returns Typst values. Input crafted to exploit a `typst` runtime
bug belongs upstream at [typst/typst](https://github.com/typst/typst/security).
Issues *specific* to this package, such as a validation gap that lets
unexpected data through, are in scope here.

## Supported versions

Only the most recent release on
[Typst Universe](https://typst.app/universe/package/gairm-import) receives fixes.
