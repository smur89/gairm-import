// Compiled against the staged package (make test-package), so the
// path must resolve from this file, not the package root.
#import "@preview/gairm-import:0.0.0": parse, object, string

#let resume = parse(
  object(
    (basics: object((name: string()), additional: true)),
    additional: true,
  ),
  path("../fixtures/resume-minimal.json"),
)
#assert.eq(resume.basics.name, "Seán Ó Murchú")
