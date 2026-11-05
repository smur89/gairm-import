// Compiled against the staged package (make test-package), so the
// path must resolve from this file, not the package root.
#import "@preview/gairm-import:0.0.0": parse

#let resume = parse(path("../fixtures/resume-minimal.json"))
#assert.eq(resume.basics.name, "Seán Ó Murchú")
