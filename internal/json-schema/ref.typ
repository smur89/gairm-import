// `$ref` resolution: a fragment of the same document, read as a JSON
// Pointer. The dispatcher (translate.typ) follows a node's `$ref`, and
// the merges (all-of.typ, conditional.typ) read a raw member's target.

#import "../core/pointer.typ": _percent-decode, _read-pointer, _pointer-get
#import "keyword.typ": _bail

// The target of `ref` in the document `root`. `seen` is the chain of
// refs traversed so far; a repeat means the schema contains itself — a
// tree that nests a tree, or an alias of an alias. A translated schema
// is a finite tree, so it can't, and the translator panics before
// Typst's recursion limit fires deep in the stack.
#let _resolve-ref(ref, root, seen) = {
  // `#/` is not the root: as a JSON Pointer, `/` names the key "".
  if ref == "#" {
    _bail("$ref \"#\" cannot reference the document root.")
  }
  if not ref.starts-with("#/") {
    _bail(
      "only internal $ref (starting with \"#/\") is supported, got: "
        + repr(ref)
        + ".",
    )
  }
  if ref in seen {
    _bail(
      "recursive $ref: "
        + (seen + (ref,)).map(repr).join(" → ")
        + " refers back to itself. A translated schema is a finite tree, so a schema that contains itself (a tree of trees, a list of lists) cannot be translated.",
    )
  }
  // The fragment is a URI's, so it is percent-decoded into the pointer
  // (RFC 3986) before the pointer is read (RFC 6901): `%25` is `%`.
  let pointer = _percent-decode(ref.slice(1))
  if pointer == none {
    _bail(
      "$ref "
        + repr(ref)
        + " has a malformed percent escape; `%` must start a `%XX` hex escape of UTF-8 bytes (write `%25` for a literal `%`).",
    )
  }
  let read = _read-pointer(pointer)
  if read.bad != none {
    _bail(
      "$ref "
        + repr(ref)
        + " has an invalid escape; RFC 6901 only allows `~0` (tilde) and `~1` (slash).",
    )
  }
  // RFC 6901: `~1` / `~0` unescape, empty segments are the "" key, and
  // a numeric segment indexes an array (e.g. "#/allOf/0") or names a key.
  let found = _pointer-get(root, read.path)
  if found.missing != none {
    _bail(
      "$ref "
        + repr(ref)
        + " could not be resolved (segment "
        + repr(str(found.missing))
        + " missing).",
    )
  }
  found.value
}

// A raw node with its `$ref`s followed, for the merges, which read a
// member after it translated: each ref is then known to resolve
// without a cycle.
#let _follow-refs(js, ctx) = {
  let js = js
  while type(js) == dictionary and "$ref" in js {
    js = _resolve-ref(js.at("$ref"), ctx.root, ())
  }
  js
}
