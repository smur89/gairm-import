// The one walk over schema and value. validate, coerce and parse all
// derive from it, so they cannot disagree about a kind: each kind's
// behaviour is its descriptor in kinds/registry.typ, and this file
// holds no per-kind logic.
//
// _walk(schema, value, ctx) -> (errors, value, fatal):
//   errors  every validation error, in walk order
//   value   the model: absent keys and items dropped, unknown keys
//           dropped, leaves through their kind's model
//   fatal   none, or the first place in walk order where the value
//           leaves no sound model, as (path, expected, got) for
//           coerce's panic
//
// Only the public entry points panic on a result; the walk itself
// panics only on a schema it cannot read (an unknown kind, which only
// a hand-built node can carry).

#import "core/ctx.typ": _absent
#import "core/error.typ": _coerce-message, _format-report
#import "kinds/registry.typ": _kinds
#import "kinds/constraint.typ": _constraint-errors

#let _walk(schema, value, ctx) = {
  if _absent(value, ctx) { return (errors: (), value: none, fatal: none) }
  let d = _kinds.at(schema.kind, default: none)
  if d == none {
    panic(
      "gairm-import: unknown schema kind "
        + repr(schema.kind)
        + "; build schemas with the constructors.",
    )
  }
  if d.walk != none { return (d.walk)(schema, value, ctx, _walk) }
  let r = (d.check)(schema, value, ctx)
  if r.fatal != none { return r }
  let errors = if r.errors == () and d.family != none {
    _constraint-errors(schema, d.family, r.value, ctx.path)
  } else { r.errors }
  (errors: errors, value: (d.model)(r.value), fatal: none)
}

// The entry points, each over a finished walk result, so lib.typ can
// call `_walk` itself and spend no extra call frame on the way in.

/// The model from a walk result. Panics only where the value left no
/// sound model; every other error is the caller's to have checked.
#let _coerce-result(r) = {
  if r.fatal != none {
    panic(_coerce-message(r.fatal.path, r.fatal.expected, r.fatal.got))
  }
  r.value
}

/// The model from a walk result, or a panic listing every error.
#let _parse-result(r) = {
  if r.errors != () { panic(_format-report(r.errors)) }
  r.value
}

/// Every validation error for `data`, in walk order.
#let _validate(schema, data, ctx) = _walk(schema, data, ctx).errors
#let _coerce(schema, data, ctx) = _coerce-result(_walk(schema, data, ctx))
#let _parse(schema, data, ctx) = _parse-result(_walk(schema, data, ctx))
