// Mirrors README.md, "Format validation": the messages its block shows
// under resume-schema-strict. The document is ours; the paths and
// messages must match the README's block.
#import "@preview/gairm-import:0.0.0": validate, resume-schema-strict

#assert.eq(
  validate(
    (
      basics: (email: "name", url: "example.com"),
      certificates: ((date: "2024/01/15"),),
    ),
    schema: resume-schema-strict,
  ).map(e => (e.path, e.message)),
  (
    (("basics", "email"), "expected an email (e.g. \"name@example.com\")."),
    (("basics", "url"), "expected a URI (e.g. \"https://example.com\")."),
    (
      ("certificates", 0, "date"),
      "expected an ISO-8601 date (e.g. \"2024-01-15\").",
    ),
  ),
)
