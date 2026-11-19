// The `member` and `team` schemas REFERENCE.md's examples build on, as
// "Constructors" and "Lenses and edits" define them. Not a test itself:
// the reference-* mirrors import it.
#import "@preview/gairm-import:0.0.0": *

#let member = object(
  (
    name: string(min-length: 1, max-length: 80),
    email: string(format: "email"),
    homepage: string(format: "uri"),
    joined: string(format: "date"),
    code: string(pattern: "^[A-Z]{3}$", expected: "a three-letter code"),
    age: integer(minimum: 0),
    rating: number(minimum: 0, maximum: 5, multiple-of: 0.5),
    tags: array-of(string(), min-items: 1, unique-items: true),
    phone: string(),
  ),
  required-keys: ("name", "email"),
  dependent-required: (phone: ("email",)),
)

#let team = object(
  (
    name: string(),
    lead: nullable(string()),
    members: array-of(member),
    contact: one-of(
      string(format: "email"),
      object((phone: string()), required-keys: ("phone",)),
    ),
  ),
  required-keys: ("name", "members"),
)
