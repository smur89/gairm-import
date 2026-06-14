// _format-path renders a path tuple as a human-readable string.

#import "../internal/errors.typ": _format-path

#assert.eq(_format-path(()), "<root>")
#assert.eq(_format-path(("basics",)), "basics")
#assert.eq(_format-path(("basics", "email")), "basics.email")
#assert.eq(_format-path(("work", 0)), "work[0]")
#assert.eq(_format-path(("work", 0, "position")), "work[0].position")
#assert.eq(_format-path(("work", 0, "highlights", 2)), "work[0].highlights[2]")
