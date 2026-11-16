// Compiled against the staged package (make test-package), so the
// path must resolve from this file, not the package root.
#import "@preview/gairm-import:0.0.0": parse, object, string

#let resume = parse(
  path("../fixtures/resume-minimal.json"),
  schema: object(
    (basics: object((name: string()), additional: true)),
    additional: true,
  ),
)
#assert.eq(resume.basics.name, "Seán Ó Murchú")
