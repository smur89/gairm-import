// Mirrors REFERENCE.md, "Schema paths and edits": each example, and that the
// edits keep what they don't touch. The calls match REFERENCE.md; the
// asserts are ours.
#import "@preview/gairm-import:0.0.0": *
#import "reference-schemas.typ": member, team

// A field a renderer adds.
#let with-logo = add-field(team, ("logo",), string(format: "uri"))
#assert.eq(schema-get(with-logo, ("logo",)), string(format: "uri"))
#assert.eq(with-logo.required-keys, team.required-keys)
// Splicing the shape into a new object drops the required keys.
#assert(
  "required-keys" not in object((..team.shape, logo: string(format: "uri"))),
)

// A role on every member, required.
#let with-role = add-field(
  team,
  ("members", "items", "role"),
  enum-of(("lead", "dev")),
  required: true,
)
#assert.eq(
  schema-get(with-role, ("members", "items")).required-keys,
  ("name", "email", "role"),
)

// Members' names as content, so they splice into markup.
#let content-names = schema-put(
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
#let open-members = schema-update(
  team,
  ("members", "items"),
  m => (..m, additional: true),
)
#let opened = schema-get(open-members, ("members", "items"))
#assert.eq(opened.additional, true)
#assert.eq(opened.shape, member.shape)
#assert.eq(opened.dependent-required, member.dependent-required)

// Require a member's joining date, then relax it again.
#let dated = set-required(team, ("members", "items"), ("joined",))
#let undated = unset-required(dated, ("members", "items"), ("joined",))
#assert.eq(schema-get(dated, ("members", "items")).required-keys, (
  "name",
  "email",
  "joined",
))
#assert.eq(undated, team)

// Paths join with `+`.
#assert.eq(
  schema-get(team, ("members",) + ("items", "tags")),
  schema-get(team, ("members", "items", "tags")),
)

// Every uri field to a corporate pattern.
#let corporate-uri = string(
  pattern: "^https://(corp|docs)\.example\.com/",
  expected: "a corporate URL",
)
#let corporate-schema = find-paths(team, string(format: "uri")).fold(
  team,
  (schema, path) => schema-put(schema, path, corporate-uri),
)
#assert.eq(find-paths(corporate-schema, string(format: "uri")), ())
#assert.eq(
  schema-get(corporate-schema, ("members", "items", "homepage")),
  corporate-uri,
)
