// _coerce on primitive schema nodes: content-type wraps the string
// into Typst content; everything else is identity.

#import "../internal/coerce.typ": _coerce
#import "../internal/schema.typ": str-type, content-type, number-type

#assert.eq(_coerce(str-type, "hi"), "hi")
#assert.eq(_coerce(number-type, 42), 42)
#assert.eq(_coerce(number-type, 3.14), 3.14)

#let wrapped = _coerce(content-type, "summary text")
#assert.eq(type(wrapped), content)
