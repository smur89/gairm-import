# Security policy

## Reporting a vulnerability

If you've found a security issue in `gairm-import` — for example, a way for a
malicious `resume.json` to escape into shell execution, exfiltrate environment
data via the host running `typst compile`, or otherwise compromise the
compiler — please **do not** open a public issue.

Instead, open a private report via [GitHub Security Advisories](https://github.com/smur89/gairm-import/security/advisories/new).
I'll acknowledge within a few days and work with you on a fix.

## Scope

`gairm-import` is a Typst data-loading library — it reads a JSON file from
disk, validates the shape against a JSON Schema (the canonical
[JSON Resume schema](https://jsonresume.org/schema) is the bundled default),
and returns a Typst dict. The most realistic attack surface is malicious input
crafted to exploit a `typst` runtime bug; please report those upstream at
[typst/typst](https://github.com/typst/typst/security). Issues *specific* to
this package (e.g. a validation gap that lets unexpected data shapes through,
or a path-handling bug in `parse`) are in scope here.

## Supported versions

Only the most recent published release on [Typst Universe](https://typst.app/universe/package/gairm-import)
receives fixes.
