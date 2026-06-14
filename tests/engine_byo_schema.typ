// Architectural readiness: the validate / coerce engines are pure
// functions of (schema, value). They contain no hardcoded knowledge
// of resume-schema — only the public `validate-resume` / `coerce-
// resume` wrappers in lib.typ bind the canonical schema. This test
// exercises the engines against a hand-rolled extension schema so a
// future refactor that accidentally hardcodes resume-schema into the
// engine fails loudly.
//
// A later iteration could expose this BYO path publicly (e.g. by
// re-exporting the combinators and a generic `validate`/`coerce`
// from lib.typ) to support JSON-Resume+ schemas where renderers
// layer extra fields on top of the canonical surface — alta-typst's
// `preferences` / `labels` would be the first such consumer.

#import "../internal/validate.typ": _validate
#import "../internal/coerce.typ": _coerce
#import "../internal/schema.typ": str-type, content-type, number-type, array-of, object

// A renderer-specific extension schema — not part of the canonical
// JSON Resume spec, but the engines must walk it indistinguishably.
#let extension-schema = object((
  greeting: content-type,
  rating: number-type,
  recipients: array-of(str-type),
  details: object((
    title: str-type,
    bullets: array-of(content-type),
  )),
))

#let payload = (
  greeting: "Hello",
  rating: 5,
  recipients: ("world", "everyone"),
  details: (
    title: "Welcome",
    bullets: ("first point", "second point"),
  ),
)

// Validation runs cleanly.
#assert.eq(_validate(extension-schema, payload, ()), ())

// Coercion produces the expected shape: content fields wrapped, str
// and number passed through.
#let model = _coerce(extension-schema, payload)
#assert.eq(type(model.greeting), content)
#assert.eq(model.rating, 5)
#assert.eq(model.recipients, ("world", "everyone"))
#assert.eq(model.details.title, "Welcome")
#assert.eq(type(model.details.bullets.at(0)), content)

// Validation still reports issues with the same shape as for the
// canonical schema — paths and messages are schema-agnostic.
#let errs = _validate(extension-schema, (greeting: 42, rating: "high"), ())
#assert.eq(errs.len(), 2)
#assert.eq(errs.at(0).path, ("greeting",))
#assert.eq(errs.at(1).path, ("rating",))
