// `$ref` resolution: a fragment of the same document, read as a JSON
// Pointer. The dispatcher (translate.typ) follows a node's `$ref`, and
// the merges (all-of.typ, conditional.typ) read a raw member's target.

#import "../core/pointer.typ": _percent-decode, _read-pointer, _pointer-get
#import "keyword.typ": _bail, _json

// The target of `ref`, a `$ref` on the node at `ctx`, as `(value, at)`:
// `at` is the target's JSON Pointer, where the translation continues.
// `ctx.seen` is the chain of refs traversed so far; a repeat means the
// schema contains itself — a tree that nests a tree, or an alias of an
// alias. A translated schema is a finite tree, so it can't, and the
// translator panics before Typst's recursion limit fires deep in the
// stack.
#let _resolve-ref(ref, ctx) = {
  // `#/` is not the root: as a JSON Pointer, `/` names the key "".
  if ref == "#" {
    _bail(ctx, "$ref \"#\" cannot reference the document root.")
  }
  if not ref.starts-with("#/") {
    _bail(
      ctx,
      "only internal $ref (starting with \"#/\") is supported, got: "
        + _json(ref)
        + ".",
    )
  }
  if ref in ctx.seen {
    _bail(
      ctx,
      "recursive $ref: "
        + (ctx.seen + (ref,)).map(_json).join(" → ")
        + " refers back to itself. A translated schema is a finite tree, so a schema that contains itself (a tree of trees, a list of lists) cannot be translated.",
    )
  }
  // The fragment is a URI's, so it is percent-decoded into the pointer
  // (RFC 3986) before the pointer is read (RFC 6901): `%25` is `%`.
  let pointer = _percent-decode(ref.slice(1))
  if pointer == none {
    _bail(
      ctx,
      "$ref "
        + _json(ref)
        + " has a malformed percent escape; `%` must start a `%XX` hex escape of UTF-8 bytes (write `%25` for a literal `%`).",
    )
  }
  let read = _read-pointer(pointer)
  if read.bad != none {
    _bail(
      ctx,
      "$ref "
        + _json(ref)
        + " has an invalid escape; RFC 6901 only allows `~0` (tilde) and `~1` (slash).",
    )
  }
  // RFC 6901: `~1` / `~0` unescape, empty segments are the "" key, and
  // a numeric segment indexes an array (e.g. "#/allOf/0") or names a key.
  let found = _pointer-get(ctx.root, read.path)
  if found.missing != none {
    _bail(
      ctx,
      "$ref "
        + _json(ref)
        + " could not be resolved (segment "
        + _json(str(found.missing))
        + " missing).",
    )
  }
  (value: found.value, at: pointer)
}

// A raw node with its `$ref`s followed, for the merges, which read a
// member after it translated: each ref is then known to resolve
// without a cycle.
#let _follow-refs(js, ctx) = {
  let js = js
  while type(js) == dictionary and "$ref" in js {
    js = _resolve-ref(js.at("$ref"), (..ctx, seen: ())).value
  }
  js
}
