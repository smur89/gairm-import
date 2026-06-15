// Architectural pin: the validate / coerce engines are pure functions
// of (schema, value). They contain no hardcoded knowledge of
// resume-schema — `validate-resume` / `coerce-resume` in lib.typ just
// pre-bind the canonical schema. This test exercises the BYO surface
// (combinators + generic `validate` / `coerce`, all re-exported from
// lib.typ) so a future refactor that accidentally hardcodes
// resume-schema into the engine fails loudly, and so the public
// JSON-Resume+ surface stays stable for downstream renderers — e.g.
// alta-typst's `preferences` / `labels` extension.

#import "../lib.typ": validate, coerce, str-type, content-type, number-type, array-of, object

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
#assert.eq(validate(extension-schema, payload), ())

// Coercion produces the expected shape: content fields wrapped, str
// and number passed through.
#let model = coerce(extension-schema, payload)
#assert.eq(type(model.greeting), content)
#assert.eq(model.rating, 5)
#assert.eq(model.recipients, ("world", "everyone"))
#assert.eq(model.details.title, "Welcome")
#assert.eq(type(model.details.bullets.at(0)), content)

// Validation still reports issues with the same shape as for the
// canonical schema — paths and messages are schema-agnostic.
#let errs = validate(extension-schema, (greeting: 42, rating: "high"))
#assert.eq(errs.len(), 2)
#assert.eq(errs.at(0).path, ("greeting",))
#assert.eq(errs.at(1).path, ("rating",))

// required-keys flows through end-to-end against an extension schema:
// missing-required errors interleave with type and unknown-key
// errors, all in one report. resume-schema itself declares no
// required keys (v0.1 strict-but-optional), so this is the only path
// that exercises the architectural hook.
#let strict-schema = object(
  (title: str-type, body: content-type),
  required-keys: ("title", "body"),
)
#assert.eq(validate(strict-schema, (title: "hi", body: "ok")), ())

#let missing-errs = validate(strict-schema, (title: "hi"))
#assert.eq(missing-errs.len(), 1)
#assert.eq(missing-errs.at(0).path, ("body",))
#assert(missing-errs.at(0).message.contains("missing required key"))

// Coercer still produces a model for the present keys when one
// required key is missing — coercion is shape-blind and trusts the
// caller to have run validation first.
#let partial = coerce(strict-schema, (title: "hi",))
#assert.eq(partial.keys(), ("title",))
