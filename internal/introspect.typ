// Schema-shape inspection helpers. Debugging an extension schema
// otherwise means `repr(schema)` (noisy dict dump) or hand-walking
// `.shape` accessors. Introspection here stays read-only; edits live
// in lens.typ.
//
// Path tuples use the lens-compatible `"items"` segment for array
// descent so `paths-of-kind` output round-trips through `lens` and
// `lens-get`. The `[]` suffix in `describe-schema` is display-only.

#import "lens.typ": lens, lens-get

#let _leaf-kinds = (
  "str", "content", "number",
  "date-string", "uri-string", "email-string",
  "enum",
)

// Alphabetical pair ordering — diff-stable output regardless of
// dictionary insertion order in the source.
#let _sorted-pairs(d) = d.pairs().sorted(key: p => p.at(0))

// Render `key  kind` with the key left-padded to `width` so columns
// align inside one object. enum nodes carry their values inline for
// at-a-glance debugging; longer leaf kinds (date-string, uri-string,
// email-string) speak for themselves.
#let _leaf-suffix(sub) = if sub.kind == "enum" {
  "enum (" + sub.values.map(repr).join(", ") + ")"
} else {
  sub.kind
}

#let _pad-right(s, width) = s + " " * (width - s.len())

// Recursive pretty-printer. `indent` is the prefix prepended to every
// emitted line at the current depth; children add two more spaces.
// Each recursive call returns the block for ONE schema node, which
// the caller stitches into the parent's lines.
#let _describe(schema, indent) = {
  if schema.kind == "object" {
    let pairs = _sorted-pairs(schema.shape)
    // Compute key-column width over leaf children only — nested
    // objects/arrays emit their header on the next line, so their key
    // width is the bare `key:` rather than `key  kind`.
    let leaf-keys = pairs
      .filter(p => p.at(1).kind not in ("object", "array"))
      .map(p => p.at(0))
    let arr-leaf-keys = pairs
      .filter(p => p.at(1).kind == "array" and p.at(1).elem.kind != "object")
      .map(p => p.at(0) + "[]")
    let widths = (leaf-keys + arr-leaf-keys).map(k => k.len())
    let col = if widths.len() == 0 { 0 } else { calc.max(..widths) + 2 }
    let lines = pairs.map(((key, sub)) => {
      if sub.kind == "object" {
        indent + key + ":\n" + _describe(sub, indent + "  ")
      } else if sub.kind == "array" and sub.elem.kind == "object" {
        indent + key + "[]:\n" + _describe(sub.elem, indent + "  ")
      } else if sub.kind == "array" {
        // Array of leaf — show `key[]  <leaf-kind>` on a single line.
        indent + _pad-right(key + "[]", col) + _leaf-suffix(sub.elem)
      } else {
        indent + _pad-right(key, col) + _leaf-suffix(sub)
      }
    })
    if lines.len() == 0 { "" } else { lines.join("\n") }
  } else if schema.kind == "array" {
    // Top-level (or directly-nested) array node. Object element is
    // expanded under an "[]" header; leaf element is reported inline.
    if schema.elem.kind == "object" {
      indent + "[]:\n" + _describe(schema.elem, indent + "  ")
    } else {
      indent + "[] " + _leaf-suffix(schema.elem)
    }
  } else {
    indent + _leaf-suffix(schema)
  }
}

#let describe-schema(schema) = _describe(schema, "")

// Walk every leaf and collect lens-compatible paths whose terminal
// kind matches `kind-name`. Object descent uses the key as the
// segment; array descent uses the literal "items" so the returned
// tuples plug straight into `lens(path)`.
#let _walk-paths(schema, path, kind-name) = {
  if schema.kind == "object" {
    _sorted-pairs(schema.shape)
      .map(((key, sub)) => _walk-paths(sub, path + (key,), kind-name))
      .fold((), (acc, ps) => acc + ps)
  } else if schema.kind == "array" {
    _walk-paths(schema.elem, path + ("items",), kind-name)
  } else if schema.kind == kind-name {
    (path,)
  } else {
    ()
  }
}

// Container kinds (`object`, `array`) are deliberately rejected — the
// walker descends through them, so accepting them would silently
// return () for every call and mask the typo.
#let paths-of-kind(schema, kind-name) = {
  assert(
    kind-name in _leaf-kinds,
    message: "json-resume: paths-of-kind kind-name " + repr(kind-name) +
      " is not a recognised leaf kind. Expected one of: " +
      _leaf-kinds.join(", ") + ".",
  )
  _walk-paths(schema, (), kind-name)
}

// Thin wrapper over `lens-get(lens(path), schema).kind` — keeps the
// common "what kind is at X" debugging step a single call.
#let kind-at(schema, path) = lens-get(lens(path), schema).kind
