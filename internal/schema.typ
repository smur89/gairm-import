// Type combinators for the JSON Resume schema. Each node carries a
// `kind` tag so the validator and coercer engines can dispatch on
// structural type without ad-hoc type sniffing.

#let str-type     = (kind: "str")
#let content-type = (kind: "content")
#let number-type  = (kind: "number")

#let array-of(elem) = (kind: "array", elem: elem)
#let object(shape)  = (kind: "object", shape: shape)
