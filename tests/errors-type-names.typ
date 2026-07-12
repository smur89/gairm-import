// _type-name-of maps Typst types to JSON-Resume-shaped names so error
// messages read "got null" / "got integer" / "got object" instead of
// Typst's raw "type(none)" / "int" / "dictionary" reprs.

#import "../internal/errors.typ": _type-name-of

#assert.eq(_type-name-of("hi"), "string")
#assert.eq(_type-name-of(42), "integer")
#assert.eq(_type-name-of(3.14), "number")
#assert.eq(_type-name-of(true), "boolean")
#assert.eq(_type-name-of(()), "array")
#assert.eq(_type-name-of((:)), "object")
#assert.eq(_type-name-of(none), "null")
