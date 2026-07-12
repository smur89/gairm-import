// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens-panic-messages.typ.
//
// Coverage rule: every `_bail` / `panic` site in the target module
// gets a pin. Substring rule: pins fit on a single source line
// (multi-line concatenation breaks contiguous-byte matching) and
// avoid embedded `\"` (escape processing doesn't round-trip through
// `read()`).

#let src = read("../internal/json-schema.typ")

// Every translator panic flows through `_bail`'s prefix; pinning the
// prefix catches a project-wide rename that misses this file.
#assert(src.contains("gairm-import: schema-from-json-schema"))

// --- $ref resolution -------------------------------------------------

#assert(src.contains("only internal $ref (starting with"))
#assert(src.contains("cyclic $ref detected"))
#assert(src.contains("cannot reference the document root"))
#assert(src.contains("could not be resolved"))
// Suffix-only match dodges the escaped `\"$ref\"` quoting.
#assert(src.contains("$ref\\\" must be a string"))

// --- translator dispatch + entry / fallthrough guards ---------------

#assert(src.contains("unsupported JSON Schema keyword"))
#assert(src.contains("Conditional schemas (if/then/else) and dependencies"))
#assert(src.contains("expected a parsed JSON Schema dict or path"))
#assert(src.contains("unrecognised JSON Schema fragment"))

// --- composition keywords (#108) -------------------------------------

#assert(src.contains("sibling keywords beside"))
#assert(src.contains("must be a non-empty array of schemas"))
#assert(src.contains("members must be schema objects"))
#assert(src.contains("allOf members must all be object schemas"))
#assert(src.contains("conflicting schemas for key"))
#assert(src.contains("allOf members declare conflicting additionalProperties"))
#assert(src.contains("not\\\" must be a schema object"))

// --- per-keyword shape checks (suffix-only — see escape note above) -

#assert(src.contains("enum\\\" must be an array of values"))
#assert(src.contains("cannot be combined with enum/const"))
#assert(src.contains("pattern\\\" must be a string"))
#assert(src.contains("unsupported string format"))
#assert(src.contains("array schema missing"))
#assert(src.contains("items\\\" must be a schema object"))
#assert(src.contains("properties\\\" must be an object"))
#assert(src.contains("required\\\" must be an array of field names"))
#assert(
  src.contains("additionalProperties\\\" must be a schema, true, or false"),
)
#assert(src.contains("open object schemas"))
#assert(src.contains("must be declared or covered"))

// --- type-union dispatch ($X, "null" only; #84 tracks strict-null) -

#assert(src.contains("only supported as nullable wraps"))

// --- constraint keywords (#76) --------------------------------------

#assert(src.contains("must be a non-negative integer"))
#assert(src.contains("must be a number"))
#assert(src.contains("must be > 0"))
#assert(src.contains("must be a boolean"))
// Inclusive vs exclusive bound contradictions.
#assert(src.contains("is unsatisfiable"))
#assert(src.contains("leave no satisfying value"))
