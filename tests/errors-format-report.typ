// _format-report turns a list of errors into a panic-ready string.

#import "../internal/errors.typ": _format-report

#let one = _format-report((
  (path: ("basics", "email"), message: "expected string, got integer."),
))
#assert(one.contains("1 problem"))
#assert(one.contains("basics.email"))
#assert(one.contains("expected string"))

#let many = _format-report((
  (path: ("basics", "email"), message: "expected string, got integer."),
  (path: ("work", 0, "positon"), message: "unknown key \"positon\"."),
))
#assert(many.contains("2 problems"))
#assert(many.contains("basics.email"))
#assert(many.contains("work[0].positon"))
