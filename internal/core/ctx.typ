// What a walk over schema and value carries down: where it is, and
// the options that change how it judges. Options reach the engine only
// through here, never as globals or extra parameters.
//
// Absence is decided here and nowhere else. JSON `null` (Typst's
// `none`) at a value position counts as the key being absent: no type
// error, no recursion, and coerce drops it from the model. A required
// key holding null is missing; a null dependent trigger does not fire.
// `strict-null` (off until it is wired to an option) will make null an
// ordinary value that kinds accept or reject.

/// A fresh context at `path` (the data path, as str / int segments).
#let _ctx(path: (), strict-null: false) = (
  path: path,
  strict-null: strict-null,
)

/// `ctx` one segment deeper.
#let _at(ctx, seg) = (..ctx, path: ctx.path + (seg,))

/// Whether `value` counts as absent.
#let _absent(value, ctx) = value == none and not ctx.strict-null

/// Whether `key` is present in `dict`. Strict mode must tell a missing
/// key from an explicit null, so this tests membership rather than
/// `dict.at(key, default: none)`.
#let _has(dict, key, ctx) = key in dict and not _absent(dict.at(key), ctx)
