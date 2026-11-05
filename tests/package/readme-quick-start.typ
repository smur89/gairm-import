// Mirrors README.md, "Quick start". The import, the parse call and
// resume.json (this directory) match the README; the asserts are ours.
#import "@preview/gairm-import:0.0.0": parse

#let resume = parse(path("resume.json"))
// hand `resume` to any compatible Typst CV template

#assert.eq(resume.basics.name, "Seán Ó Murchú")
#assert.eq(resume.basics.email, "sean@example.com")
#assert.eq(resume.work.len(), 1)
#assert.eq(resume.work.first().name, "Acme Corp")
#assert.eq(
  resume.work.first().highlights,
  ("Led the event-sourcing platform migration.",),
)
