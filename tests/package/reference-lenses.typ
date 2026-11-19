// Mirrors REFERENCE.md, "Lenses and edits": each example, and that the
// edits keep what they don't touch. The calls match REFERENCE.md; the
// asserts are ours.
#import "@preview/gairm-import:0.0.0": *
#import "reference-schemas.typ": member, team

// A field a renderer adds.
#let with-logo = add-field(team, (), "logo", string(format: "uri"))
#assert.eq(lens-get(with-logo, ("logo",)), string(format: "uri"))
#assert.eq(with-logo.required-keys, team.required-keys)
// Splicing the shape into a new object drops the required keys.
#assert.eq(
  object((..team.shape, logo: string(format: "uri"))).required-keys,
  (),
)

// A role on every member, required.
#let with-role = add-field(
  team,
  ("members", "items"),
  "role",
  enum-of(("lead", "dev")),
  required: true,
)
#assert.eq(
  lens-get(with-role, ("members", "items")).required-keys,
  ("name", "email", "role"),
)

// Members' names as content, so they splice into markup.
#let content-names = lens-put(
  team,
  ("members", "items", "name"),
  markup(),
)
#assert.eq(
  parse(content-names, (
    name: "Core",
    members: ((name: "Ada", email: "a@b.c"),),
  )),
  (name: "Core", members: ((name: [Ada], email: "a@b.c"),)),
)

// Spreading a member keeps everything it doesn't change.
#let open-members = lens-over(
  team,
  ("members", "items"),
  m => (..m, additional: true),
)
#let opened = lens-get(open-members, ("members", "items"))
#assert.eq(opened.additional, true)
#assert.eq(opened.shape, member.shape)
#assert.eq(opened.dependent-required, member.dependent-required)

// Require a member's joining date, then relax it again.
#let dated = set-required(
  team,
  ("members", "items"),
  ("name", "email", "joined"),
)
#let undated = unset-required(dated, ("members", "items"), ("joined",))
#assert.eq(lens-get(dated, ("members", "items")).required-keys, (
  "name",
  "email",
  "joined",
))
#assert.eq(undated, team)

// A location is a path or `(lens: path)`, and paths join with `+`.
#assert.eq(
  lens-get(team, (lens: ("members",) + ("items", "tags"))),
  lens-get(team, ("members", "items", "tags")),
)

// Every uri field to a corporate pattern.
#let corporate-uri = string(
  pattern: "^https://(corp|docs)\.example\.com/",
  expected: "a corporate URL",
)
#let corporate-schema = find-paths(team, string(format: "uri")).fold(
  team,
  (schema, path) => lens-put(schema, path, corporate-uri),
)
#assert.eq(find-paths(corporate-schema, string(format: "uri")), ())
#assert.eq(
  lens-get(corporate-schema, ("members", "items", "homepage")),
  corporate-uri,
)
